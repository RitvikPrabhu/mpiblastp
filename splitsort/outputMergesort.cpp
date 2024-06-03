#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <algorithm>
#include <string>
#include <limits>

struct DataEntry {
    std::string original_line;
    double bitscore;
    double evalue;

    DataEntry(const std::string& line, double b, double e) : original_line(line), bitscore(b), evalue(e) {}
};

bool compareEntries(const DataEntry& a, const DataEntry& b) {
    if (a.bitscore == b.bitscore) {
        return a.evalue < b.evalue; 
    }
    return a.bitscore > b.bitscore; 
}

int main() {
    std::ifstream infile("blastp_output_mod.out");
    std::ofstream outfile("sorted_data.txt");

    if (!infile) {
        std::cerr << "Error opening input file" << std::endl;
        return 1;
    }

    std::vector<DataEntry> data_entries;
    std::string line;

    while (std::getline(infile, line)) {
        std::istringstream ss(line);
        std::string token;
        std::vector<std::string> tokens;
        
        while (std::getline(ss, token, '\t')) {
            tokens.push_back(token);
        }

        double bitscore = 0.0;
        double evalue = std::numeric_limits<double>::max();

        if (tokens.size() >= 12) {
            if (!tokens[11].empty()) {
                bitscore = std::stod(tokens[11]);
            }
            if (!tokens[10].empty()) {
                evalue = std::stod(tokens[10]);
            }
        }

        data_entries.emplace_back(line, bitscore, evalue);
    }

    std::sort(data_entries.begin(), data_entries.end(), compareEntries);

    for (const auto& entry : data_entries) {
        outfile << entry.original_line << '\n';
    }

    infile.close();
    outfile.close();

    return 0;
}
