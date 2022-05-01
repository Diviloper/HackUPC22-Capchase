for w in 0..8 {
    let r = (rand() % 4).abs();
    switch r {
        0 => worker(w).move_up(),
        1 => worker(w).move_down(),
        2 => worker(w).move_right(),
        3 => worker(w).move_left(),
    }
}