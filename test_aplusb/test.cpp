#include <gtest/gtest.h>
#include "solution.hpp"
#include <sstream>

TEST(APLUSB, StandardIO) {
    std::istringstream mock_input("1 5\n10 20");
    std::ostringstream mock_output;
    
    solve(mock_input, mock_output);
    
    EXPECT_EQ(mock_output.str(), "6\n30\n");
}
