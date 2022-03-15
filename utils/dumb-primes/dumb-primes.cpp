#include <iostream>
#include <thread>
#include <atomic>
#include <string>
#include <vector>

//bool gRun = true;
std::atomic<uint64_t> gNumberOfPrimes{0u};

bool checkIsPrime(size_t number) {
    for (size_t i = 2; i<number; ++i) {
        if ((number % i) == 0) {
            return false;
        }
    }
    return true;
}

void countPrimes(const size_t startNumber, const size_t stepSize) {
    size_t currentNumber = startNumber;
    for (size_t currentNumber = startNumber; currentNumber < 250000; currentNumber += stepSize) {
        if (checkIsPrime(currentNumber)) {
            gNumberOfPrimes.fetch_add(1, std::memory_order_relaxed);
        }
    }
}

int main(int argc, char** argv)
{
    unsigned int numberOfThreads = std::thread::hardware_concurrency();
    if (argc == 2) {
        int userNumberOfThreads;
        try {
            userNumberOfThreads = std::stoi(argv[1]);
        } catch(...) {
            std::cerr << "Invalid argument (number of threads has to be a number)" << std::endl;
            return EXIT_FAILURE;
        }
        if (userNumberOfThreads <= 0) {
            std::cerr << "number of threads has to be at least 1" << std::endl;
            return EXIT_FAILURE;
        }
        numberOfThreads = static_cast<unsigned int>(userNumberOfThreads);
    }
    std::cout << "Running with thread count " << numberOfThreads << std::endl;

    constexpr size_t startNumber = 2;
    std::vector<std::thread> threads(numberOfThreads);
    for (unsigned int i = 0; i < numberOfThreads; ++i) {
        threads[i] = std::thread{&countPrimes, startNumber + i, numberOfThreads};
    }

    /*
    std::cout << "Press enter to stop...";
    std::cin.ignore(1);
    gRun = false;*/
    for (auto& thread : threads) {
        thread.join();
    }
    std::cout << "Found " << gNumberOfPrimes.load(std::memory_order_relaxed) << " prime numbers" << std::endl;
    return EXIT_SUCCESS;
}
