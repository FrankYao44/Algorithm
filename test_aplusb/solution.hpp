#include <iostream>
//namespace test_aplusb {
// 1. Solution: 纯算法逻辑
class Solution {
public:
    int add(int a, int b) {
        return a + b;
    }
};

// 2. IO Handler: IO 处理逻辑
// 传入引用以便在测试中注入 mock 的输入流
void solve(std::istream& in, std::ostream& out) {
    int a, b;
    Solution sol;
    while (in >> a >> b) {
        out << sol.add(a, b) << "\n";
    }
}


