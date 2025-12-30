# Lab6 实验报告

### 练习0：填写已有实验

> 本实验依赖实验2/3/4/5。请把你做的实验2/3/4/5的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”“LAB5”的注释相应部分。并确保编译通过。 注意：为了能够正确执行lab6的测试应用程序，可能需对已完成的实验2/3/4/5的代码进行进一步改进。 由于我们在进程控制块中记录了一些和调度有关的信息，例如Stride、优先级、时间片等等，因此我们需要对进程控制块的初始化进行更新，将调度有关的信息初始化。同时，由于时间片轮转的调度算法依赖于时钟中断，你可能也要对时钟中断的处理进行一定的更新。

**解答：** 

1. teap.c文件更改
   
   在原来lab3编写的代码的基础上添加对`sched_class_proc_tick`函数的调用：
   
  ```c++
   //  在时钟中断时调用调度器的 sched_class_proc_tick 函数
   if (current) sched_class_proc_tick(current);
   ```

2. proc.c文件更改
   
   在alloc_proc函数处增加lab6新增成员变量的初始化：
   
   ```c++
   // alloc_proc(void)函数新增
   proc->rq = NULL;
   list_init(&proc->run_link);
   proc->time_slice = 0;
   memset(&proc->lab6_run_pool, 0, sizeof(proc->lab6_run_pool));
   proc->lab6_stride = 0;
   proc->lab6_priority = 1;
   ```

### 练习1：理解调度器框架的实现

> 请仔细阅读和分析调度器框架的相关代码，特别是以下两个关键部分的实现：
>
> 在完成练习0后，请仔细阅读并分析以下调度器框架的实现：
>
> - 调度类结构体 sched_class 的分析：请详细解释 sched_class 结构体中每个函数指针的作用和调用时机，分析为什么需要将这些函数定义为函数指针，而不是直接实现函数。
> - 运行队列结构体 run_queue 的分析：比较lab5和lab6中 run_queue 结构体的差异，解释为什么lab6的 run_queue 需要支持两种数据结构（链表和斜堆）。
> - 调度器框架函数分析：分析 sched_init()、wakeup_proc() 和 schedule() 函数在lab6中的实现变化，理解这些函数如何与具体的调度算法解耦。
>
> 对于调度器框架的使用流程，请在实验报告中完成以下分析：
>
> - 调度类的初始化流程：描述从内核启动到调度器初始化完成的完整流程，分析 default_sched_class 如何与调度器框架关联。
> - 进程调度流程：绘制一个完整的进程调度流程图，包括：时钟中断触发、proc_tick 被调用、schedule() 函数执行、调度类各个函数的调用顺序。并解释 need_resched 标志位在调度过程中的作用
> - 调度算法的切换机制：分析如果要添加一个新的调度算法（如stride），需要修改哪些代码？并解释为什么当前的设计使得切换调度算法变得容易。

**解答：**

1) 调度类结构体 `sched_class` 分析

    `sched_class` 把“调度策略”抽象成一组统一接口，内核调度框架只依赖这些接口，而不依赖具体算法实现。

- `const char *name`
   - 作用：调度器名字
   - 调用时机：`sched_init()` 完成初始化后会打印当前调度类名字

- `void (*init)(struct run_queue *rq)`
   - 作用：初始化运行队列 `rq` 的内部数据结构与元数据
   - 调用时机：`sched_init()` 中设置好 `rq->max_time_slice` 后调用

- `void (*enqueue)(struct run_queue *rq, struct proc_struct *proc)`
   - 作用：把一个“就绪态（RUNNABLE）进程”加入运行队列
   - 调用时机：
      - `wakeup_proc()`：进程从睡眠等状态变为 RUNNABLE 且不是 `current` 时入队
      - `schedule()`：当前进程仍为 RUNNABLE（时间片用完或主动让出 CPU 前）会被重新入队

- `void (*dequeue)(struct run_queue *rq, struct proc_struct *proc)`
   - 作用：把某个进程从运行队列中移除（通常是将要运行的那个进程）
   - 调用时机：`schedule()` 在选出 `next` 后，会对 `next` 执行 `dequeue`

- `struct proc_struct *(*pick_next)(struct run_queue *rq)`
   - 作用：从运行队列中选出“下一个应运行的进程”（只返回指针，不负责切换）
   - 调用时机：`schedule()` 中调用，若返回 `NULL`，框架会选择 `idleproc`

- `void (*proc_tick)(struct run_queue *rq, struct proc_struct *proc)`
   - 作用：处理时钟中断 tick 对“当前正在运行进程”的影响
   - 调用时机：时钟中断里调用 `sched_class_proc_tick(current)`，进而调用当前调度类的 `proc_tick`

    为什么要用“函数指针”而不是直接写死实现：

    - 解耦：`schedule()/wakeup_proc()` 只负责“什么时候调度/维护就绪队列”，而“怎么挑选下一个进程”由调度类实现。
    - 易扩展和切换：新增算法只需实现同一组接口（例如 stride），并在 `sched_init()` 切换 `sched_class` 指针即可。

2) 运行队列结构体 `run_queue` 分析（对比 lab5 与 lab6）

- lab5：`sched.h` 只有 `schedule()`/`wakeup_proc()` 声明；`schedule()` 直接在全局进程链表 `proc_list` 上扫描，找下一个 RUNNABLE 进程。这种做法实现简单，但每次调度都可能遍历多个进程，时间复杂度较高；并且“就绪队列”与“调度策略”混在一起。

- lab6：引入 `struct run_queue`，包括`list_entry_t run_list`就绪队列链表（RR 等算法直接用队列）；`unsigned int proc_num`队列中就绪进程数；`int max_time_slice`最大时间片；`skew_heap_entry_t *lab6_run_pool`：用于 stride 的斜堆（优先队列）根指针。

    为什么 lab6 的 `run_queue` 要支持两种数据结构（链表、斜堆）：

    - RR 核心需求是 FIFO，先来先服务，用完时间片放队尾。用链表入队/出队即可，操作为 $O(1)$。

    - Stride 核心需求是每次选 stride 最小的进程，若用普通链表，需要在整个就绪队列中遍历找最小值，通常是 $O(n)$；而用斜堆这类优先队列可以更高效地维护“最小 stride”元素。

    因此同一个框架要同时支持 RR 和 stride，就把两种结构都放进 `run_queue`，由具体调度类选择使用哪一种。

3) 调度器框架函数分析

- `sched_init()`（lab6 新增）
   - 初始化定时器链表 `timer_list`。
   - 设置当前调度类：`sched_class = &default_sched_class`（RR）。
   - 初始化全局运行队列 `rq`：设置 `rq->max_time_slice = MAX_TIME_SLICE`，并调用 `sched_class->init(rq)`。
   - 此实现不关心 RR/stride 的数据结构细节，统一交给 `init()`。

- `wakeup_proc()`
   - lab5：只负责把进程状态改为 RUNNABLE。
   - lab6：除了改状态外，还会在“被唤醒进程不是当前进程”时调用 `sched_class_enqueue(proc)` 将其加入运行队列。
   - lab6入队细节由 `sched_class->enqueue()` 决定。

- `schedule()`
   - lab5：围绕 `proc_list` 做循环扫描，找到下一个 RUNNABLE。
   - lab6：统一流程为：清除 `current->need_resched`；若 `current` 仍为 RUNNABLE，则把 `current` 重新入队；调用 `pick_next()` 得到 `next`，若非空则 `dequeue(next)`；若 `next==NULL` 则选 `idleproc`；调用`proc_run(next)` 完成上下文切换。
   - lab6只规定“入队/选取/出队”的时机，选取规则完全由 `pick_next()` 控制。

4) 调度类初始化流程（从启动到 sched_init 完成）

    整体流程可以概括为：

    - 内核启动完成基本初始化后，会调用 `sched_init()`。
    - `sched_init()` 选择具体调度类。
    - `sched_init()` 初始化 `rq` 并调用 `default_sched_class.init(rq)`。
    - 之后内核所有入队/出队/选择下一个进程/时钟 tick 处理，都通过 `sched_class` 的函数指针间接调用到 RR（或 stride）的实现。

5) 进程调度流程与 `need_resched` 作用

    **典型流程图**

    ```
    时钟中断 IRQ_S_TIMER
                |
                v
    interrupt_handler(): clock_set_next_event(); ...
                |
                v
    sched_class_proc_tick(current)
                |
                v
    RR_proc_tick(): time_slice--, 若为0则 need_resched=1
                |
                v
    trap() 返回前（从用户态陷入时）检查 need_resched
                |
                v
    schedule()
       - current.need_resched=0
       - current 若 RUNNABLE => enqueue(current)
       - next = pick_next(); 
       - dequeue(next)
       - next==NULL => idleproc
       - proc_run(next) 上下文切换
    ```

    **`need_resched`**

    - `need_resched` 是延迟调度的标志位：中断处理或系统调用等路径只负责置位，真正的调度切换在安全的位置调用 `schedule()` 进行。
    - 在 RR 中时间片耗尽时置位，表示必须让出 CPU，体现时间片轮转。
    - 在 `trap()` 中：只有从用户态陷入才会因为 `need_resched` 调用 `schedule()`，避免在内核关键路径中随意切换导致不一致。

6) 调度算法的切换机制：如何添加/切换到 stride

    如果要新增一个 stride 调度算法，修改点如下：

    - 实现一个新的 `struct sched_class`，补全 `init/enqueue/dequeue/pick_next/proc_tick`。
    - 在 `sched_init()` 中将 `sched_class` 从 `&default_sched_class` 切换为 `&stride_sched_class`。

### 练习2：实现 Round Robin 调度算法

> 完成练习0后，建议大家比较一下（可用kdiff3等文件比较软件）个人完成的lab5和练习0完成后的刚修改的lab6之间的区别，分析了解lab6采用RR调度算法后的执行过程。理解调度器框架的工作原理后，请在此框架下实现时间片轮转（Round Robin）调度算法。
>
> 注意有“LAB6”的注释，你需要完成 kern/schedule/default_sched.c 文件中的 RR_init、RR_enqueue、RR_dequeue、RR_pick_next 和 RR_proc_tick 函数的实现，使系统能够正确地进行进程调度。代码中所有需要完成的地方都有“LAB6”和“YOUR CODE”的注释，请在提交时特别注意保持注释，将“YOUR CODE”替换为自己的学号，并且将所有标有对应注释的部分填上正确的代码。
>
> 提示，请在实现时注意以下细节：
>
> - 链表操作：list_add_before、list_add_after等。
> - 宏的使用：le2proc(le, member) 宏等。
> - 边界条件处理：空队列的处理、进程时间片耗尽后的处理、空闲进程的处理等。
>
> 请在实验报告中完成：
>
> - 比较一个在lab5和lab6都有, 但是实现不同的函数, 说说为什么要做这个改动, 不做这个改动会出什么问题
>   - 提示: 如kern/schedule/sched.c里的函数。你也可以找个其他地方做了改动的函数。
> - 描述你实现每个函数的具体思路和方法，解释为什么选择特定的链表操作方法。对每个实现函数的关键代码进行解释说明，并解释如何处理边界情况。
> - 展示 make grade 的输出结果，并描述在 QEMU 中观察到的调度现象。
> - 分析 Round Robin 调度算法的优缺点，讨论如何调整时间片大小来优化系统性能，并解释为什么需要在 RR_proc_tick 中设置 need_resched 标志。
> - 拓展思考：如果要实现优先级 RR 调度，你的代码需要如何修改？当前的实现是否支持多核调度？如果不支持，需要如何改进？

**解答 :**

1) 对比lab5和lab6实现的`schedule()`

- lab5 的 `schedule()`：
   - 通过遍历全局进程链表 `proc_list` 来寻找下一个 `PROC_RUNNABLE` 的进程。
   - 每次调度都可能扫描多个进程，效率较低；并且“谁在就绪、就绪队列长什么样”与“调度策略”耦合在一起。

- lab6 的 `schedule()`：
   - 调度框架先把当前进程（如果仍 RUNNABLE）通过 `enqueue` 放回运行队列，再通过 `pick_next` 选择下一个进程，并对其 `dequeue`。
   - 这样一来，RR 可以用 FIFO 队列自然实现轮转；stride 可以用斜堆实现每次取最小 stride。

  如果不做这个改动，lab5 只是扫描 `proc_list`，并没有独立的就绪队列语义，这样难以实现RR的用完的时间片放队尾，且切换到 stride 时，需要进行相当多的改动。

2) RR 各函数实现思路与代码说明

   RR_init用于初始化运行队列

    ```cpp
    static void
    RR_init(struct run_queue *rq)
    {
        // LAB6: YOUR CODE
        list_init(&(rq->run_list)); // 把 rq->run_list 初始化为空双向循环链表头
        rq->proc_num = 0; // 把运行队列中的进程计数器置 0，表示当前队列无进程
    }
    ```

    RR_enqueue用于把进程插入到队尾，保证 FIFO。

    ```cpp
    static void
    RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
    {
        // LAB6: YOUR CODE
        if(list_empty(&(proc->run_link))){ // 当 proc 的 run_link 链表结点为空时
            list_add_before(&(rq->run_list), &(proc->run_link)); //  把新进程挂到rq->run_list前，run_list是循环双向链表头，在头前面插入等价于放到队尾
            if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) { // 检查 proc 当前 time_slice 是否未初始化（0）或超过队列允许的最大时间片
                proc->time_slice = rq->max_time_slice; // 分配时间片
            }
            proc->rq = rq; // 把 proc 的 rq 指针设置为当前运行队列
            rq->proc_num ++;
        }
    }
    ```

    RR_dequeue用于把指定进程从队列中移除。

    ```cpp
    static void
    RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
    {
        // LAB6: YOUR CODE
        if(!list_empty(&(proc->run_link)) && proc->rq == rq){ // proc->run_link 非空并且 proc 所属的 rq 是传入的 rq
            list_del_init(&(proc->run_link)); // 从链表中删除 proc->run_link，并把该结点重置为链表初始状态
            rq->proc_num --;
        }
    }
    ```

    RR_pick_next用于选择队头进程作为下一个运行者。

    ```cpp
    static struct proc_struct *
    RR_pick_next(struct run_queue *rq)
    {
        // LAB6: YOUR CODE
        list_entry_t *le = list_next(&(rq->run_list)); // 获取运行队列中第一个进程的链表结点
        if (le != &(rq->run_list)) { // 不能是头部本身
            return le2proc(le, run_link); // 用 le2proc 宏把链表结点转换为对应的 proc_struct 指针并返回
        }
        return NULL;
    }
    ```

    RR_proc_tick用于每次时钟 tick 消耗一个时间片单位；时间片耗尽则请求调度。

    ```cpp
    static void
    RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
    { // 此函数在当前进程的时钟滴答事件触发时被调用，应减少 proc->time_slice 并在耗尽时将进程的需要重新调度标志置为 1
        // LAB6: YOUR CODE
        if (proc->time_slice > 0) {
            proc->time_slice --;
        }
        if (proc->time_slice == 0) {
            proc->need_resched = 1;
        }
    }
    ```

3) make grade 输出与 QEMU 现象

- `make grade` 输出：

  ```text

  ```

- 在 QEMU 中的调度现象：
  - 启动阶段能看到 `sched class: RR_scheduler`，说明当前使用 RR 调度类。
  - 运行 `priority` 用户程序后，先后输出多次 `set priority to X`，并出现 `main: fork ok, now need to wait pids.`，表明用户程序创建了多个可运行子进程并进入等待/竞争 CPU 的状态。
  - 内核持续响应时钟中断并输出 `100 ticks`，说明 tick 触发链路正常、调度相关的 tick 处理在持续发生。
  - 最终输出 `End of Test.`，随后出现`kernel panic ... EOT: kernel seems ok.`，表示测试按预期跑完。

4) RR 优缺点、时间片调整、为什么要设置 need_resched

- 优点：
   - 公平直观：所有就绪进程轮流执行，不容易饿死。
   - 实现简单：队列入队/出队 $O(1)$，易于验证正确性。

- 缺点：
   - 不区分任务类型：CPU 密集型和 I/O 密集型一视同仁，交互性可能不如更复杂算法。
   - 时间片选择敏感：时间片过小导致频繁切换（上下文切换开销增大）；时间片过大导致响应变差。

- 时间片（`MAX_TIME_SLICE`）如何影响性能：
   - 时间片小：更流畅、响应好，但切换次数增多。
   - 时间片大：切换次数少，吞吐可能更高，但交互延迟更大。

- 为什么在 `RR_proc_tick` 中设置 `need_resched`：
   - 中断处理里不直接做复杂切换，而是置位 `need_resched`，让 `trap()` 在安全点调用 `schedule()`。
   - 这使时间片耗尽与真正切换解耦，避免在中断上下文或内核关键路径中随意切换造成不一致。

5) 拓展思考：优先级 RR 与多核支持

- 若实现“优先级 RR”，可以怎么改：
  按优先级改变时间片。在 `enqueue` 时令 `proc->time_slice = rq->max_time_slice * f(priority)`，优先级高获得更长时间片。

- 当前实现是否支持多核（SMP）：
  当前不支持。因为只有一个全局 `rq`，并且没有真正实现 `rq_lock`，也没有 per-CPU 的 run queue。

- 若要支持多核，需要如何改进：
  为每个 CPU 维护独立的 `run_queue`与调度上下文；增加 run queue 的锁与关键路径的并发保护；实现负载均衡，在 CPU 之间迁移就绪进程。
