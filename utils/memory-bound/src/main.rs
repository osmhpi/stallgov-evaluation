use rand::prelude::*;
use std::sync::*;

fn main() {
    // 100 MB vector
    let mut vec = (0..25_000_000).collect::<Vec<usize>>();
    vec.shuffle(&mut thread_rng());

    // for i in &vec {
    // println!("i: {}", i);
    // }
    let vec = Arc::new(vec);

    println!("Vec filled!");

    let mut handles = Vec::new();
    for _ in 0..num_cpus::get() {
        let thread_vec = Arc::clone(&vec);
        let handle = std::thread::spawn(move || {
            let mut result = 0;
            let mut current_value = 0;
            for _ in 0..10_000_000 {
                current_value += rand::random::<bool>() as usize;
                current_value = current_value.clamp(0, thread_vec.len() - 1);

                current_value = *thread_vec.get(current_value).unwrap();
                result += current_value;

                current_value = *thread_vec.get(current_value).unwrap();
                result += current_value;

                current_value = *thread_vec.get(current_value).unwrap();
                result += current_value;

                current_value = *thread_vec.get(current_value).unwrap();
                result += current_value;

                current_value = *thread_vec.get(current_value).unwrap();
                result += current_value;

                current_value = *thread_vec.get(current_value).unwrap();
                result += current_value;

                current_value = *thread_vec.get(current_value).unwrap();
                result += current_value;
            }
            println!("Result: {}", result);
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }
}
