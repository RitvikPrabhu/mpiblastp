#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <map>
#include <vector>

void splitAndStore(const std::string& inputFileName) {
    std::ifstream inputFile(inputFileName);
    if (!inputFile.is_open()) {
        std::cerr << "Could not open the file " << inputFileName << std::endl;
        return;
    }

    std::string line;
    std::map<std::string, std::vector<std::string>> fileContents;

    while (getline(inputFile, line)) {
        std::istringstream iss(line);
        std::string key;
        // iss >> key;
        if (iss >> key) {
            fileContents[key].push_back(line);
        }
    }
    inputFile.close();

    int fileIndex = 1;
    for (const auto& pair : fileContents) {
        std::string outputFileName = "sequencePair" + std::to_string(fileIndex++) + ".txt";
        std::ofstream outputFile(outputFileName);
        if (!outputFile.is_open()) {
            std::cerr << "Could not open the file " << outputFileName << std::endl;
            continue;
        }
        for (const auto& content : pair.second) {
            outputFile << content << std::endl;
        }
        outputFile.close();
    }
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <input_file>" << std::endl;
        return 1;
    }

    std::string inputFileName = argv[1];
    splitAndStore(inputFileName);
    return 0;
}
