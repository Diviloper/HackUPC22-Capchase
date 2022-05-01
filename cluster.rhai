if !("initialized" in memory) {
    memory.initialized = true;
    memory.centroid = getClusterCentroid(map);

    memory.movements = #{};
    memory.worker_positions = [];
    memory.worker_counters = [];
    for work in map.workers {
        let pos = `${work.x}-${work.y}`;
        memory.worker_positions += pos;
        memory.worker_counters += 0;
    }
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

let currentCentroid = getClusterCentroid(map);
let centroid = [(memory.centroid[0] + currentCentroid[0]) / 2, (memory.centroid[1] + currentCentroid[1]) / 2];

info(`Cluster centroid: [${centroid[0]}, ${centroid[1]}]`);

let nextPositions = [];

for w in 0..8 {
    let work = worker(w);
    let x = work.x;
    let y = work.y;
    let pos = `${x}-${y}`;
    info(pos);

    let blockedAdjacentPositions = [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].map(|p| `${p[0]}-${p[1]}`).filter(|p| p in nextPositions);
    // info(`W${w} ${blockedAdjacentPositions}`);

    if connectedToCluster(x, y, centroid, map) {

        let destination = dijkstra(x, y, map, blacklist + blockedAdjacentPositions);
        if destination[0] {
            let nextPos = moveInDirection(work, x, y, destination[3], destination[4]);
            // info(`W${w} con, md (${pos}) -> (${nextPos})`);
            nextPositions.push(nextPos);
            continue;
        }
        
        destination = moveRandomly(work);
        if destination[0] {
            // info(`W${w} con, mr (${pos}) -> (${destination[1]}-${destination[2]})`);
            nextPositions.push(`${destination[1]}-${destination[2]}`);
        }
    } else {
        let nextPos = moveInDirection(work, x, y, centroid[0], centroid[1]);
        // info(`W${w} not con (${pos}) -> (${nextPos})`);
        nextPositions.push(nextPos);
    }
}

let newMovements = #{};
for pos in nextPositions {
    if pos in memory.movements {
        newMovements[pos] = memory.movements[pos] + 1;
    } else {
        newMovements[pos] = 1;
    }
}
memory.movements = newMovements;


fn moveRandomly(work) {
    let x = work.x;
    let y = work.y;

    let options = [0, 1, 2, 3];
    options.shuffle();
    for r in options {
        switch r {
            0 => {
                if !insideLimits(x, y + 1) {
                    continue;
                }
                work.move_up();
                return [true, x, y + 1];
            }
            1 => {
                if !insideLimits(x, y - 1) {
                    continue;
                }
                work.move_down();
                return [true, x, y - 1];
            }
            2 => {
                if !insideLimits(x + 1, y) {
                    continue;
                }
                work.move_right();
                return [true, x + 1, y];
            }
            3 => {
                if !insideLimits(x - 1, y) {
                    continue;
                }
                work.move_left();
                return [true, x - 1, y];
            }
        }
    }
    return [false];
}

fn connectedToCluster(x, y, centroid, map) {
    let color = worker(0).color;
    let visited = #{};
    let nextStops = [[x, y]];
    while nextStops.len > 0 {
        let next = nextStops.remove(0);
        let nx = next[0];
        let ny = next[1];
        let pos = `${nx}-${ny}`;

        if [nx, ny] == centroid {
            return true;
        }
        if !insideLimits(nx, ny) || pos in visited || map[nx][ny] != color {
            continue;
        }

        visited[pos] = true;

        let neighbors = [[nx - 1, ny], [nx + 1, ny], [nx, ny - 1], [nx, ny + 1]];
        nextStops += neighbors;
    }
    return false;
}

fn dijkstra(x, y, map, blacklist) {
    let visited = #{};
    let nextStops = [[x, y, x, y]];
    let destination = [false];
    while nextStops.len > 0 {
        let next = nextStops.remove(0);
        let nx = next[0];
        let ny = next[1];
        if distance(x, y, nx, ny) > 20 {
            break;
        }
        let previous = [next[2], next[3]];
        let pos = `${nx}-${ny}`;
        if !insideLimits(nx, ny) || pos in visited || pos in blacklist {
            continue;
        }
        visited[pos] = previous;
        let neighbors = [[nx - 1, ny, nx, ny], [nx + 1, ny, nx, ny], [nx, ny - 1, nx, ny], [nx, ny + 1, nx, ny]];
        neighbors.shuffle();
        nextStops += neighbors;
        if enemyCell(nx, ny, map) {
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

fn getMovementsOfDistance(d) {
    let movements = [[d, 0], [-d, 0], [0, d], [0, -d]];
    for i in 1..d {
        movements.push([d-i, i]);
        movements.push([-d+i, i]);
        movements.push([d-i, -i]);
        movements.push([-d+i, -i]);
    }
    return movements;
}

fn insideLimits(x, y) {
    return x >= 0 && x < 40 && y >= 0 && y < 40;
}

fn enemyCell(x, y, map) {
    return map[x][y] != worker(0).color;
}

fn getClusterCentroid(map) {
    let xSum = 0;
    let ySum = 0;
    for w in 0..8 {
        let work = worker(w);
        xSum += work.x;
        ySum += work.y;
    }
    return [xSum / 8, ySum / 8];
}

fn distance(x0, y0, x1, y1) {
    return (x0 - x1).abs() + (y0 - y1).abs();
}

fn moveInDirection(work, x0, y0, x1, y1) {
    let dx = (x0 - x1).abs();
    let dy = (y0 - y1).abs();
    if (dx >= dy) {
        if (x0 > x1) {
            work.move_left();
            return `${x0 - 1}-${y0}`;
        }
        if (x0 < x1) {
            work.move_right();
            return `${x0 + 1}-${y0}`;
        }
    } else {
        if (y0 > y1) {
            work.move_down();
            return `${x0}-${y0 - 1}`;
        }
        if (y0 < y1) {
            work.move_up();
            return `${x0}-${y0 + 1}`;
        }
    }
}