if !("assigned" in memory) {
    let warriors = [0, 1, 2, 3, 4, 5, 6, 7];
    warriors.sort(|a, b| {
        let wa = worker(a);
        let wb = worker(b);
        let da = distance_from_center(wa.x, wa.y);
        let db = distance_from_center(wb.x, wb.y);
        if (da < db) {
            return -1;
        } else if (da == db) {
            return 0;
        } else {
            return 1;
        }
    });

    if (worker(0).y > 20) {
        if (worker(0).x < 20) {
            memory.quadrant = 1;
        } else {
            memory.quadrant = 2;
        }
    } else {
        if (worker(0).x < 20) {
            memory.quadrant = 3;
        } else {
            memory.quadrant = 4;
        }
    }

    memory.attackers = organize_attackers(memory.quadrant, warriors.extract(0..3));
    for at in memory.attackers {
        memory[`attacker${at[1]}`] = quadrant_center(at[1]);
    }
    memory.defenders = warriors.extract(3..8);

    memory.worker_positions = [];
    memory.worker_counters = [];
    for work in map.workers {
        let pos = `${work.x}-${work.y}`;
        memory.worker_positions += pos;
        memory.worker_counters += 0;
    }
    
    memory.movements = #{};
    memory.tick = 0;

    memory.assigned = true;
} else {
    memory.tick += 1;
}

let blacklist = [];
for w in 0..32 {
    let work = map.workers[w];
    let pos = `${work.x}-${work.y}`;
    if pos == memory.worker_positions[w] {
        memory.worker_counters[w] += 1;
    } else {
        memory.worker_positions[w] = pos;
        memory.worker_counters[w] = 1;
    }

    if memory.worker_counters[w] > 5 && !(pos in blacklist) {
        blacklist += pos;
    }
}
for move in memory.movements.keys() {
    if memory.movements[move] > 3 {
        blacklist += move;
    }
}

info(`${blacklist}`);



let targets = [];
let next_positions = [];

fn organize_attackers(quadrant, attackers) {
    let top_attacker = if worker(attackers[1]).y > worker(attackers[2]).y {attackers[1]} else {attackers[2]};
    let bot_attacker = if top_attacker == attackers[1] {attackers[2]} else {attackers[1]};
    if quadrant == 1 {
        return [[attackers[0], 4], [top_attacker, 2], [bot_attacker, 3]];
    } else if quadrant == 2 {
        return [[attackers[0], 3], [top_attacker, 1], [bot_attacker, 4]];        
    } else if quadrant == 3 {
        return [[attackers[0], 2], [top_attacker, 1], [bot_attacker, 4]];        
    } else {
        return [[attackers[0], 1], [top_attacker, 2], [bot_attacker, 3]];
    }
}

fn distance(x0, y0, x1, y1) {
    return (x0 - x1).abs() + (y0 - y1).abs();
}

fn distance_from_center(x, y) {
    return (20 - x).abs() + (20 - y).abs();
}

fn quadrant_center(quadrant) {
    return switch quadrant {
        1 => [15, 25],
        2 => [25, 25],
        3 => [15, 15],
        4 => [25, 15],
    };
}

fn inside_limits(x, y, quadrant) {
    return switch quadrant {
        1 => x >= 0 && x <= 20 && y >= 20 && y < 40,
        2 => x >= 20 && x < 40 && y >= 20 && y < 40,
        3 => x >= 0 && x <= 20 && y >= 0 && y <= 20,
        4 => x >= 20 && x < 40 && y >= 0 && y <= 20,
    };
}

fn inside_expanded_limits(x, y, quadrant) {
    return switch quadrant {
        1 => x >= 0 && x <= 25 && y >= 15 && y < 40,
        2 => x >= 15 && x < 40 && y >= 15 && y < 40,
        3 => x >= 0 && x <= 25 && y >= 0 && y <= 25,
        4 => x >= 15 && x < 40 && y >= 0 && y <= 25,
    };
}

fn inside_frontier(x, y, quadrant) {
    return switch quadrant {
        1 => x >= 15 && y <= 25 && (x <= 25 || y >= 15),
        2 => x >= 15 && y >= 15 && (x <= 25 || y <= 25),
        3 => x <= 25 && y <= 25 && (x >= 15 || y >= 15),
        4 => x <= 25 && y >= 15 && (x >= 15 || y <= 25),
    };
}

fn inside_vertical_frontier(x, y, quadrant) {
    return x >= 15 && x <= 25 && switch quadrant {
        1 => y >= 15,
        2 => y >= 15,
        3 => y <= 25,
        4 => y <= 25,
    };
}

fn inside_horizontal_frontier(x, y, quadrant) {
    return y >= 15 && y <= 25 && switch quadrant {
        1 => x <= 25,
        2 => x >= 15,
        3 => x <= 25,
        4 => x >= 15,
    };
}

fn is_enemy(x, y, map) {
    return map[x][y] != worker(0).color;
}

fn is_white(x, y, map) {
    return map[x][y] == Tile::EMPTY;
}

fn bfs(x, y, map, quadrant, targets, limit_func, target_func) {
    let visited = #{};
    let nextStops = [[x, y]];
    while nextStops.len > 0 {
        let next = nextStops.remove(0);
        let x = next[0];
        let y = next[1];
        let pos = `${x}-${y}`;
        if !limit_func.call(x, y, quadrant) {
            continue;
        }
        if pos in visited {
            continue;
        } else {
            visited[pos] = true;
        }
        let neighbors = [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]];
        neighbors.shuffle();
        nextStops += neighbors;
        
        if target_func.call(x, y, map) && !(pos in targets) {
            return [true, x, y];
        }

    }
    return [false];
}

fn dijkstra(x, y, map, quadrant, targets, blacklist, limit_func, target_func) {
    let visited = #{};
    let nextStops = [[x, y, x, y]];
    let destination = [false];
    while nextStops.len > 0 {
        let next = nextStops.remove(0);
        let nx = next[0];
        let ny = next[1];
        if distance(x, y, nx, ny) > 15 {
            break;
        }
        let previous = [next[2], next[3]];
        let pos = `${nx}-${ny}`;
        if !limit_func.call(nx, ny, quadrant) || pos in visited || pos in blacklist {
            continue;
        }
        visited[pos] = previous;
        let neighbors = [[nx - 1, ny, nx, ny], [nx + 1, ny, nx, ny], [nx, ny - 1, nx, ny], [nx, ny + 1, nx, ny]];
        neighbors.shuffle();
        nextStops += neighbors;
        
        if target_func.call(nx, ny, map) && !(pos in targets) {
            destination = [true, nx, ny];
            break;
        }
    }
    if destination[0] {
        let nextStep;
        let previous = destination.extract(1..=2);
        while previous != [x, y] {
            nextStep = previous;
            previous = visited[`${previous[0]}-${previous[1]}`];
        }
        return destination + nextStep;
    } 
    return [false];
}


fn move_randomly(warrior, quadrant, limit_func) {
    let x = warrior.x;
    let y = warrior.y;
    while true {
        let r = (rand() % 4).abs();
        switch r {
            0 => {
                if !limit_func.call(x, y + 1, quadrant) {
                    continue;
                }
                warrior.move_up();
                return [x, y + 1];
            }
            1 => {
                if !limit_func.call(x, y - 1, quadrant) {
                    continue;
                }
                warrior.move_down();
                return [x, y - 1];
            }
            2 => {
                if !limit_func.call(x + 1, y, quadrant) {
                    continue;
                }
                warrior.move_right();
                return [x + 1, y];
            }
            3 => {
                if !limit_func.call(x - 1, y, quadrant) {
                    continue;
                }
                warrior.move_left();
                return [x - 1, y];
            }
        }
    }
}

fn move_direction(warrior, x0, y0, x1, y1) {
    let dx = (x0 - x1).abs();
    let dy = (y0 - y1).abs();
    if (dx >= dy) {
        if (x0 > x1) {
            warrior.move_left();
            return `${x0 - 1}-${y0}`;
        }
        if (x0 < x1) {
            warrior.move_right();
            return `${x0 + 1}-${y0}`;
        }
    } else {
        if (y0 > y1) {
            warrior.move_down();
            return `${x0}-${y0 - 1}`;
        }
        if (y0 < y1) {
            warrior.move_up();
            return `${x0}-${y0 + 1}`;
        }
    }
}


for w in memory.defenders {
    let defender = worker(w);
    let x = defender.x;
    let y = defender.y;

    let limits = if memory.defenders.index_of(w) < 3 {"inside_expanded_limits"} else {"inside_limits"};
    
    let blockedAdjacentPositions = [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].filter(|p| p in next_positions);
    let target = dijkstra(x, y, map, memory.quadrant, targets, blacklist + blockedAdjacentPositions, Fn(limits), Fn("is_enemy"));
    if target[0] {
        targets += `${target[1]}-${target[2]}`;
        next_positions += move_direction(defender, x, y, target[3], target[4]);
        continue;
    }
    
    target = move_randomly(defender, memory.quadrant, Fn(limits));
    next_positions += `${target[0]}-${target[1]}`;
}



for att in memory.attackers {
    let attacker = worker(att[0]);
    let attacker_quadrant = att[1];

    if memory.tick < 550 {
        let target = dijkstra(attacker.x, attacker.y, map, attacker_quadrant, targets, blacklist, Fn("inside_limits"), Fn("is_white"));
        if target[0] {
            next_positions += move_direction(attacker, attacker.x, attacker.y, target[3], target[4]);
            continue;
        }
        target = dijkstra(attacker.x, attacker.y, map, attacker_quadrant, targets, blacklist, Fn("inside_limits"), Fn("is_enemy"));
        if target[0] {
            next_positions += move_direction(attacker, attacker.x, attacker.y, target[3], target[4]);
            continue;
        }
    }
    memory[`attacker${attacker_quadrant}`] = sow_chaos(attacker, attacker_quadrant, memory[`attacker${attacker_quadrant}`]);
}

let newMovements = #{};
for pos in next_positions {
    if pos in memory.movements {
        newMovements[pos] = memory.movements[pos] + 1;
    } else {
        newMovements[pos] = 1;
    }
}
memory.movements = newMovements;


fn sow_chaos(attacker, quadrant, current_objective) {
    if [attacker.x, attacker.y] != current_objective {
        move_direction(attacker, attacker.x, attacker.y, current_objective[0], current_objective[1]);
        return current_objective;
    } else {
        let points = get_quadrant_points(quadrant);
        let next = points[(rand() % 4).abs()];
        while next == current_objective {
            next = points[(rand() % 4).abs()];
        }
        move_direction(attacker, attacker.x, attacker.y, next[0], next[1]);
        return next;
    }
}

fn get_quadrant_points(quadrant) {
    return switch quadrant {
        1 => [[0, 30], [10, 39], [19,30], [10, 20]],
        2 => [[20, 30], [30, 39], [39, 30], [30, 20]],
        3 => [[0, 10], [10, 19], [19, 10], [10, 0]],
        4 => [[20, 10], [30, 19], [39, 10], [30, 0]],
    };
}