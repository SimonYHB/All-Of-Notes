

- lldb动态调试

  - 什么是动态调试

  - 动态调试原理

  - 调试手机App 例如连接wechat

    - debugserver *:10011 -a Wechat
    - process connect connect://localhost:10011

  - 常用lldb指令 

    - 格式： `<command>  [<subcommand> [<subcommand>...>]] <action> [-options [option-value]] [argument [argument...]]  `

      - eg.breakpoint set -name test 为test函数设置断点

    - help 指令

    - expression <cmd-option> --<expr> 执行表达式

      - print、p、call、po

    - thread backtrace 打印堆栈信息 同bt

    - thread return 使当前函数直接返回

    - frame variable/变量 打印当前栈针(函数)的所有变量或某个变量

    - Xcode调试器对应的指令

      - thread continue、continue、c
      - thread step-in、step、s
      - thread step-over、next、n
      - thread step-out、finish
      - thread step-inst、stepi、si
      - thread step-inst-over、nexti、ni
      - s、n是代码级别，si、ni是汇编指令级别的单步运行

    - breakpoint 断点

    - 内存断点

      - watchpoint 

    - image lookup -a 通过地址找代码位置

    - Image list

      