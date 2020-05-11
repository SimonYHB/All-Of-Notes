

- LLVM

  - 什么是LLVM

    - 可用于编译器开发

  - 编译器架构

    - Frontend 生成中间代码
    - Optimizer 代码优化
    - Backend 生成机器代码

    - LLVM特点： 不同的前端后端使用统一的中间代码

  - Clang

    - 与LLVM关系
      - LLVM项目的一个人子项目
      - 基于LLVM架构的00C/C++/OC编译器前端
    - 相比于GCC
      - 编译速度快：在某些平台上，Clang的编译速度显著的快过GCC（Debug模式下编译OC速度比GGC快3倍）
      - 占用内存小：Clang生成的AST所占用的内存是GCC的五分之一左右
      -  模块化设计：Clang采用基于库的模块化设计，易于 IDE 集成及其他用途的重用
      -  诊断信息可读性强：在编译过程中，Clang 创建并保留了大量详细的元数据 (metadata)，有利于调试和错误报告
      -  设计清晰简单，容易理解，易于扩展增强
    - 源文件的编译过程
    - 语法分析
    - 语法树AST
    - LLVM IR

    - 应用
      - libclang、libTooling 用于语法书分析，语言转换等
      - Clang插件开发 用于代码检查
      - Pass开发 用于代码优化、代码混淆等
      - 开发新的编程语言

  - 插件开发实战

