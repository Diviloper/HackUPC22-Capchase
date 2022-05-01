let moves = [];
let directions = [];

if !("previous_positions" in memory) {
    memory.previous_positions = #{};
    memory.previous_movements = #{};
    memory.previous_directions = #{};
    memory.blacklist = #{};
    memory.find_empty_spaces = true;
}

moves += memory.previous_positions.keys();

let current_positions = #{};
for w in 0..32 {
    let work = map.workers[w];
    let pos = `${work.x}-${work.y}`;

    if pos in memory.previous_positions {
        current_positions[pos] = memory.previous_positions[pos] + 1;
    } else {
        current_positions[pos] = 1;
    }

    if current_positions[pos] > 5 {
        memory.blacklist[pos] = 1;
    }
}
memory.previous_positions = current_positions;

for w in 0..8 {
    moves.push(`${worker(w).x}-${worker(w).y}`);
}

let centers = [[4, 4], [34, 4], [4, 34], [34, 34]];

for centroid in centers {
    if `${centroid[0] + 1}-${centroid[1]}` in memory.blacklist && 
    `${centroid[0] - 1}-${centroid[1]}` in memory.blacklist &&
     `${centroid[0]}-${centroid[1] + 1}` in memory.blacklist &&
      `${centroid[0]}-${centroid[1] - 1}` in memory.blacklist {
        memory.blacklist[`${centroid[0]}-${centroid[1]}`] = 15;
    }
    
}

for pos in memory.blacklist.keys() {
    moves.push(pos);
    memory.blacklist[pos] += 1;
    if memory.blacklist[pos] > 20 {
        memory.blacklist.remove(pos);
    }
}

fn get_random_order() {
    let shuffled = [1, 2, 3, 4];
    shuffled.shuffle();
    return shuffled;
}

fn valid_position(x, y, moves, map) {
    return x >= 0 && x < 40 && y >= 0 && y < 40 && map[x][y] != worker(0).color && !moves.contains(`${x}-${y}`);
}

fn valid_empty_position(x, y, moves, map) {
    return x >= 0 && x < 40 && y >= 0 && y < 40 && map[x][y] == Tile::EMPTY && !moves.contains(`${x}-${y}`);
}

fn get_movements_of_distance(d) {
    let movements = [[d, 0], [-d, 0], [0, d], [0, -d]];
    for i in 1..d {
        movements.push([d-i, i]);
        movements.push([-d+i, i]);
        movements.push([d-i, -i]);
        movements.push([-d+i, -i]);
    }
    return movements;
}


fn find_closest_coords(x, y, moves, directions, map, valid_func) {
    for d in 1..40 {
        let moves = get_movements_of_distance(d);
        moves.shuffle();
        for movement in moves {
            let dx = movement[0];
            let dy = movement[1];
            if valid_func.call(x + dx, y + dy, moves, map) && !directions.contains(`${x + dx}-${y - dy}`) {
                return [x + dx, y + dy];
            }
        }
    }
    return "Nope";
}

fn move_to_closest_empty(work, moves, directions, map) {
    let x = work.x;
    let y = work.y;
    let res = find_closest_coords(x, y, moves, directions, map, Fn("valid_empty_position"));
    if res == "Nope" {
        return [false, true];
    }
    let closestX = res[0];
    let closestY = res[1];

    let order = get_random_order();

    for i in order {
        switch i {
            1 => {
                if closestX > x && !moves.contains(`${x+1}-${y}`) {
                    work.move_right();
                    return [true, x+1, y, closestX, closestY];
                }
            }
            2 => {
                if closestX < x && !moves.contains(`${x-1}-${y}`) {
                    work.move_left();
                    return [true, x-1, y, closestX, closestY];
                }
            }
            3 => {
                if closestY > y && !moves.contains(`${x}-${y+1}`) {
                    work.move_up();
                    return [true, x, y+1, closestX, closestY];
                }
            }
            4 => {
                if closestY < y && !moves.contains(`${x}-${y-1}`) {
                    work.move_down();
                    return [true, x, y-1, closestX, closestY];
                }
            }
        }   
    }

    return [false, false];

}



fn move_to_closest(work, moves, directions, map) {
    let x = work.x;
    let y = work.y;
    let res = find_closest_coords(x, y, moves, directions, map, Fn("valid_position"));
    if res == "Nope" {
        return [false];
    }
    let closestX = res[0];
    let closestY = res[1];

    let order = get_random_order();

    for i in order {
        switch i {
            1 => {
                if closestX > x && !moves.contains(`${x+1}-${y}`) {
                    work.move_right();
                    return [true, x+1, y, closestX, closestY];
                }
            }
            2 => {
                if closestX < x && !moves.contains(`${x-1}-${y}`) {
                    work.move_left();
                    return [true, x-1, y, closestX, closestY];
                }
            }
            3 => {
                if closestY > y && !moves.contains(`${x}-${y+1}`) {
                    work.move_up();
                    return [true, x, y+1, closestX, closestY];
                }
            }
            4 => {
                if closestY < y && !moves.contains(`${x}-${y-1}`) {
                    work.move_down();
                    return [true, x, y-1, closestX, closestY];
                }
            }
        }   
    }

    return [false];
}

fn move_randomly(work) {
    let r = (rand() % 4).abs();
    switch r {
        0 => {
            work.move_up();
            return [true, work.x, work.y + 1];
        }
        1 => {
            work.move_down();
            return [true, work.x, work.y - 1];
        }
        2 => {
            work.move_right();
            return [true, work.x + 1, work.y];
        }
        3 => {
            work.move_left();
            return [true, work.x - 1, work.y];
        }
    }
}

for w in 0..8 {
    let work = worker(w);
    let moved = false;

    let res;

    // if memory.find_empty_spaces && w < 4 {
    //     res = move_to_closest_empty(work, moves, directions, map);
    //     if res[0] {
    //         let movement = `${res[1]}-${res[2]}`;
    //         let direction = `${res[3]}-${res[4]}`;

    //         info(`W${w} mce ${work.x}-${work.y} -> ${movement} (${direction})`);

    //         moves.push(movement);
    //         directions.push(direction);

    //         if movement == memory.previous_movements[`${w}-d`] {
    //             memory.previous_movements[`${w}-c`] += 1;
    //         } else {
    //             memory.previous_movements[`${w}-d`] = movement;
    //             memory.previous_movements[`${w}-c`] = 1;
    //         }

    //         if direction == memory.previous_directions[`${w}-d`] {
    //             memory.previous_directions[`${w}-c`] += 1;
    //         } else {
    //             memory.previous_directions[`${w}-d`] = direction;
    //             memory.previous_directions[`${w}-c`] = 1;
    //         }

    //         moved = true;
    //     } else if res[1] {
    //         info("No more empty spaces");
    //         memory.find_empty_spaces = false;
    //     }
    // }

    if !moved {
        res = move_to_closest(work, moves, directions, map);
        if res[0] {
            let movement = `${res[1]}-${res[2]}`;
            let direction = `${res[3]}-${res[4]}`;
            
            //info(`W${w} mc ${work.x}-${work.y} -> ${movement} (${direction})`);
            
            moves.push(movement);
            directions.push(direction);
            
            if movement == memory.previous_movements[`${w}-d`] {
                memory.previous_movements[`${w}-c`] += 1;
            } else {
                memory.previous_movements[`${w}-d`] = movement;
                memory.previous_movements[`${w}-c`] = 1;
            }
            
            if direction == memory.previous_directions[`${w}-d`] {
                memory.previous_directions[`${w}-c`] += 1;
            } else {
                memory.previous_directions[`${w}-d`] = direction;
                memory.previous_directions[`${w}-c`] = 1;
            }
            
            moved = true;
        }
    }

    if !moved {
        res = move_randomly(work);
        if res[0] {
            let movement = `${res[1]}-${res[2]}`;
            
            //info(`W${w} mr ${work.x}-${work.y} -> ${res[1]}-${res[2]}`);
            
            moves.push(movement);
            
            if movement == memory.previous_movements[`${w}-d`] {
                memory.previous_movements[`${w}-c`] += 1;
            } else {
                memory.previous_movements[`${w}-d`] = movement;
                memory.previous_movements[`${w}-c`] = 1;
            }
            
            memory.previous_directions.remove(`${w}-d`);
            memory.previous_directions.remove(`${w}-c`);

            moved = true;
        }
    }

    if memory.previous_movements[`${w}-c`] > 2 {
        memory.blacklist[memory.previous_movements[`${w}-d`]] = 1;
    }

    if `${w}-c` in memory.previous_directions && memory.previous_directions[`${w}-c`] > 2 {
        memory.blacklist[memory.previous_directions[`${w}-d`]] = 1;
    }
}