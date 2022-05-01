info(`${worker(0).color}`);
let w = worker(7);
info(`Position: ${w.x}, ${w.y}`);
w.move_up();



let attacked_column_left = 10;
let attacked_column_right = 30;
let attacked_row_top = 30;
let attacked_row_bot = 10;

let column_attacker_left = worker(memory.attackers[0]);
let column_attacker_right = worker(memory.attackers[1]);
let row_attacker_top = worker(memory.attackers[2]);
let row_attacker_bot= worker(memory.attackers[3]);

if column_attacker_left.x != attacked_column_left {
    move_direction(column_attacker_left, column_attacker_left.x, column_attacker_left.y, attacked_column_left, column_attacker_left.y);
} else {

    if column_attacker_left.y == 0 {
        memory.column_direction = 1;
    }
    if column_attacker_left.y == 39 {
        memory.column_direction = -1;
    }

    if memory.column_direction == 1 {
        column_attacker_left.move_up();
    } else {
        column_attacker_left.move_down();
    }
}

if column_attacker_right.x != attacked_column_right {
    move_direction(column_attacker_right, column_attacker_right.x, column_attacker_right.y, attacked_column_right, column_attacker_right.y);
} else {

    if column_attacker_right.y == 0 {
        memory.column_direction = 1;
    }
    if column_attacker_right.y == 39 {
        memory.column_direction = -1;
    }

    if memory.column_direction == 1 {
        column_attacker_right.move_up();
    } else {
        column_attacker_right.move_down();
    }
}

if row_attacker_top.y != attacked_row_top {
    move_direction(row_attacker_top, row_attacker_top.x, row_attacker_top.y, row_attacker_top.x, attacked_row_top);
} else {
    if row_attacker_top.x == 0 {
        memory.row_direction = 1;
    }
    if row_attacker_top.x == 39 {
        memory.row_direction = -1;
    }

    if memory.row_direction == 1 {
        row_attacker_top.move_right();
    } else {
        row_attacker_top.move_left();
    }

}

if row_attacker_bot.y != attacked_row_bot{
    move_direction(row_attacker_bot, row_attacker_bot.x, row_attacker_bot.y, row_attacker_bot.x, attacked_row_bot);
} else {
    if row_attacker_bot.x == 0 {
        memory.row_direction = 1;
    }
    if row_attacker_bot.x == 39 {
        memory.row_direction = -1;
    }

    if memory.row_direction == 1 {
        row_attacker_bot.move_right();
    } else {
        row_attacker_bot.move_left();
    }
}