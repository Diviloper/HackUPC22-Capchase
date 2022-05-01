fn dijkstra(x, y, map, quadrant, targets, limit_func) {
    let visited = #{};
    let nextStops = [[x, y]];
    let previous = [x, y];
    let destination = [false];
    while nextStops.len > 0 {
        let next = nextStops.remove(0);
        let nx = next[0];
        let ny = next[1];
        let pos = `${nx}-${ny}`;
        if !limit_func.call(nx, ny, quadrant) {
            continue;
        }
        if pos in visited {
            continue;
        } else {
            visited[pos] = previous;
        }
        let neighbors = [[nx - 1, ny], [nx + 1, ny], [nx, ny - 1], [nx, ny + 1]];
        neighbors.shuffle();
        nextStops += neighbors;
        
        if is_enemy(nx, ny, map) && !(pos in targets) {
            destination = [true, nx, ny];
            break;
        }
        previous = [nx, ny];
    }
    if destination[0] {
        let nextStep;
        while previous != [x, y] {
            nextStep = previous;
            previous = visited[`${previous[0]}-${previous[1]}`];
        }
        return destination + nextStep;
    } 
    return [false];
}
