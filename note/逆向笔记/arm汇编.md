

- 汇编

  - 寄存器
    - 堆栈指针
      - sp 栈顶
      - fp x29 栈底
    - 程序状态寄存器
      - cpsr 存放cmp等指令结果 
      - spsr 异常状态使用
    - 零寄存器，里面储存的值为0
      - wrz (4个字节 32bit)
      - xrz (8个字节 64bit)
    - 程序计数器 
      - pc 存储当前cpu正在执行的指令
    - 链接寄存器
      - lr x30 存储函数返回地址
  - 常用指令
  - 堆栈
    - 叶子函数 
      - sub sp, sp, #16
      - add sp, sp, #16
    - 非叶子函数
      - sub sp, sp, #32 //开辟空间
      - stp x29, x30, [sp, #16] //存储fp, lr
      - add x29,  sp, #16 //定位sp
      - bl ...
      - ldp x29, x30, [sp, #16] //恢复fp, lr
      - add sp, sp, #32

  