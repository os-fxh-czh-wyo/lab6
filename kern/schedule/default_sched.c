#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * RR_init initializes the run-queue rq with correct assignment for
 * member variables, including:
 *
 *   - run_list: should be an empty list after initialization.
 *   - proc_num: set to 0
 *   - max_time_slice: no need here, the variable would be assigned by the caller.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_init(&(rq->run_list)); // 把 rq->run_list 初始化为空双向循环链表头
    rq->proc_num = 0; // 把运行队列中的进程计数器置 0，表示当前队列无进程
}

/*
 * RR_enqueue inserts the process ``proc'' into the tail of run-queue
 * ``rq''. The procedure should verify/initialize the relevant members
 * of ``proc'', and then put the ``run_link'' node into the queue.
 * The procedure should also update the meta data in ``rq'' structure.
 *
 * proc->time_slice denotes the time slices allocation for the
 * process, which should set to rq->max_time_slice.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
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

/*
 * RR_dequeue removes the process ``proc'' from the front of run-queue
 * ``rq'', the operation would be finished by the list_del_init operation.
 * Remember to update the ``rq'' structure.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    if(!list_empty(&(proc->run_link)) && proc->rq == rq){ // proc->run_link 非空并且 proc 所属的 rq 是传入的 rq
        list_del_init(&(proc->run_link)); // 从链表中删除 proc->run_link，并把该结点重置为链表初始状态
        rq->proc_num --;
    }
}

/*
 * RR_pick_next picks the element from the front of ``run-queue'',
 * and returns the corresponding process pointer. The process pointer
 * would be calculated by macro le2proc, see kern/process/proc.h
 * for definition. Return NULL if there is no process in the queue.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
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

/*
 * RR_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current process. proc->need_resched
 * is the flag variable for process switching.
 */
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

struct sched_class default_sched_class = {
    .name = "RR_scheduler",
    .init = RR_init,
    .enqueue = RR_enqueue,
    .dequeue = RR_dequeue,
    .pick_next = RR_pick_next,
    .proc_tick = RR_proc_tick,
};
