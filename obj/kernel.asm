
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000b1517          	auipc	a0,0xb1
ffffffffc020004e:	19e50513          	addi	a0,a0,414 # ffffffffc02b11e8 <buf>
ffffffffc0200052:	000b5617          	auipc	a2,0xb5
ffffffffc0200056:	67660613          	addi	a2,a2,1654 # ffffffffc02b56c8 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc020aff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	01d050ef          	jal	ffffffffc020587e <memset>
    cons_init(); // init the console
ffffffffc0200066:	4da000ef          	jal	ffffffffc0200540 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	83e58593          	addi	a1,a1,-1986 # ffffffffc02058a8 <etext>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	85650513          	addi	a0,a0,-1962 # ffffffffc02058c8 <etext+0x20>
ffffffffc020007a:	11e000ef          	jal	ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1ac000ef          	jal	ffffffffc020022a <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	530000ef          	jal	ffffffffc02005b2 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	7d2020ef          	jal	ffffffffc0202858 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	07b000ef          	jal	ffffffffc0200904 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	079000ef          	jal	ffffffffc0200906 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	05d030ef          	jal	ffffffffc02038ee <vmm_init>
    sched_init();
ffffffffc0200096:	054050ef          	jal	ffffffffc02050ea <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	53f040ef          	jal	ffffffffc0204dd8 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	45a000ef          	jal	ffffffffc02004f8 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	057000ef          	jal	ffffffffc02008f8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	6d3040ef          	jal	ffffffffc0204f78 <cpu_idle>

ffffffffc02000aa <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000aa:	7179                	addi	sp,sp,-48
ffffffffc02000ac:	f406                	sd	ra,40(sp)
ffffffffc02000ae:	f022                	sd	s0,32(sp)
ffffffffc02000b0:	ec26                	sd	s1,24(sp)
ffffffffc02000b2:	e84a                	sd	s2,16(sp)
ffffffffc02000b4:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b6:	c901                	beqz	a0,ffffffffc02000c6 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b8:	85aa                	mv	a1,a0
ffffffffc02000ba:	00006517          	auipc	a0,0x6
ffffffffc02000be:	81650513          	addi	a0,a0,-2026 # ffffffffc02058d0 <etext+0x28>
ffffffffc02000c2:	0d6000ef          	jal	ffffffffc0200198 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c6:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c8:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000ca:	000b1997          	auipc	s3,0xb1
ffffffffc02000ce:	11e98993          	addi	s3,s3,286 # ffffffffc02b11e8 <buf>
        c = getchar();
ffffffffc02000d2:	148000ef          	jal	ffffffffc020021a <getchar>
ffffffffc02000d6:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d8:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000dc:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000e0:	ff650693          	addi	a3,a0,-10
ffffffffc02000e4:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e8:	02054963          	bltz	a0,ffffffffc020011a <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ec:	02a95f63          	bge	s2,a0,ffffffffc020012a <readline+0x80>
ffffffffc02000f0:	cf0d                	beqz	a4,ffffffffc020012a <readline+0x80>
            cputchar(c);
ffffffffc02000f2:	0da000ef          	jal	ffffffffc02001cc <cputchar>
            buf[i ++] = c;
ffffffffc02000f6:	009987b3          	add	a5,s3,s1
ffffffffc02000fa:	00878023          	sb	s0,0(a5)
ffffffffc02000fe:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc0200100:	11a000ef          	jal	ffffffffc020021a <getchar>
ffffffffc0200104:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200106:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010a:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010e:	ff650693          	addi	a3,a0,-10
ffffffffc0200112:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200116:	fc055be3          	bgez	a0,ffffffffc02000ec <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc020011a:	70a2                	ld	ra,40(sp)
ffffffffc020011c:	7402                	ld	s0,32(sp)
ffffffffc020011e:	64e2                	ld	s1,24(sp)
ffffffffc0200120:	6942                	ld	s2,16(sp)
ffffffffc0200122:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200124:	4501                	li	a0,0
}
ffffffffc0200126:	6145                	addi	sp,sp,48
ffffffffc0200128:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	eb81                	bnez	a5,ffffffffc020013a <readline+0x90>
            cputchar(c);
ffffffffc020012c:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012e:	00905663          	blez	s1,ffffffffc020013a <readline+0x90>
            cputchar(c);
ffffffffc0200132:	09a000ef          	jal	ffffffffc02001cc <cputchar>
            i --;
ffffffffc0200136:	34fd                	addiw	s1,s1,-1
ffffffffc0200138:	bf69                	j	ffffffffc02000d2 <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc020013a:	c291                	beqz	a3,ffffffffc020013e <readline+0x94>
ffffffffc020013c:	fa59                	bnez	a2,ffffffffc02000d2 <readline+0x28>
            cputchar(c);
ffffffffc020013e:	8522                	mv	a0,s0
ffffffffc0200140:	08c000ef          	jal	ffffffffc02001cc <cputchar>
            buf[i] = '\0';
ffffffffc0200144:	000b1517          	auipc	a0,0xb1
ffffffffc0200148:	0a450513          	addi	a0,a0,164 # ffffffffc02b11e8 <buf>
ffffffffc020014c:	94aa                	add	s1,s1,a0
ffffffffc020014e:	00048023          	sb	zero,0(s1)
}
ffffffffc0200152:	70a2                	ld	ra,40(sp)
ffffffffc0200154:	7402                	ld	s0,32(sp)
ffffffffc0200156:	64e2                	ld	s1,24(sp)
ffffffffc0200158:	6942                	ld	s2,16(sp)
ffffffffc020015a:	69a2                	ld	s3,8(sp)
ffffffffc020015c:	6145                	addi	sp,sp,48
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc0200160:	1101                	addi	sp,sp,-32
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200166:	3dc000ef          	jal	ffffffffc0200542 <cons_putc>
    (*cnt)++;
ffffffffc020016a:	65a2                	ld	a1,8(sp)
}
ffffffffc020016c:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016e:	419c                	lw	a5,0(a1)
ffffffffc0200170:	2785                	addiw	a5,a5,1
ffffffffc0200172:	c19c                	sw	a5,0(a1)
}
ffffffffc0200174:	6105                	addi	sp,sp,32
ffffffffc0200176:	8082                	ret

ffffffffc0200178 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200178:	1101                	addi	sp,sp,-32
ffffffffc020017a:	862a                	mv	a2,a0
ffffffffc020017c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017e:	00000517          	auipc	a0,0x0
ffffffffc0200182:	fe250513          	addi	a0,a0,-30 # ffffffffc0200160 <cputch>
ffffffffc0200186:	006c                	addi	a1,sp,12
{
ffffffffc0200188:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020018a:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020018c:	2d8050ef          	jal	ffffffffc0205464 <vprintfmt>
    return cnt;
}
ffffffffc0200190:	60e2                	ld	ra,24(sp)
ffffffffc0200192:	4532                	lw	a0,12(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret

ffffffffc0200198 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200198:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020019a:	02810313          	addi	t1,sp,40
{
ffffffffc020019e:	f42e                	sd	a1,40(sp)
ffffffffc02001a0:	f832                	sd	a2,48(sp)
ffffffffc02001a2:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a4:	862a                	mv	a2,a0
ffffffffc02001a6:	004c                	addi	a1,sp,4
ffffffffc02001a8:	00000517          	auipc	a0,0x0
ffffffffc02001ac:	fb850513          	addi	a0,a0,-72 # ffffffffc0200160 <cputch>
ffffffffc02001b0:	869a                	mv	a3,t1
{
ffffffffc02001b2:	ec06                	sd	ra,24(sp)
ffffffffc02001b4:	e0ba                	sd	a4,64(sp)
ffffffffc02001b6:	e4be                	sd	a5,72(sp)
ffffffffc02001b8:	e8c2                	sd	a6,80(sp)
ffffffffc02001ba:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001be:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c0:	2a4050ef          	jal	ffffffffc0205464 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c4:	60e2                	ld	ra,24(sp)
ffffffffc02001c6:	4512                	lw	a0,4(sp)
ffffffffc02001c8:	6125                	addi	sp,sp,96
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001cc:	ae9d                	j	ffffffffc0200542 <cons_putc>

ffffffffc02001ce <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001ce:	1101                	addi	sp,sp,-32
ffffffffc02001d0:	e822                	sd	s0,16(sp)
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3a>
ffffffffc02001dc:	e426                	sd	s1,8(sp)
ffffffffc02001de:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc02001e0:	4481                	li	s1,0
    cons_putc(c);
ffffffffc02001e2:	360000ef          	jal	ffffffffc0200542 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	0405                	addi	s0,s0,1
ffffffffc02001ec:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc02001ee:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x14>
    cons_putc(c);
ffffffffc02001f2:	4529                	li	a0,10
    (*cnt)++;
ffffffffc02001f4:	0027841b          	addiw	s0,a5,2
ffffffffc02001f8:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001fa:	348000ef          	jal	ffffffffc0200542 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fe:	60e2                	ld	ra,24(sp)
ffffffffc0200200:	8522                	mv	a0,s0
ffffffffc0200202:	6442                	ld	s0,16(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    cons_putc(c);
ffffffffc0200208:	4529                	li	a0,10
ffffffffc020020a:	338000ef          	jal	ffffffffc0200542 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020020e:	4405                	li	s0,1
}
ffffffffc0200210:	60e2                	ld	ra,24(sp)
ffffffffc0200212:	8522                	mv	a0,s0
ffffffffc0200214:	6442                	ld	s0,16(sp)
ffffffffc0200216:	6105                	addi	sp,sp,32
ffffffffc0200218:	8082                	ret

ffffffffc020021a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020021a:	1141                	addi	sp,sp,-16
ffffffffc020021c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020021e:	358000ef          	jal	ffffffffc0200576 <cons_getc>
ffffffffc0200222:	dd75                	beqz	a0,ffffffffc020021e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200224:	60a2                	ld	ra,8(sp)
ffffffffc0200226:	0141                	addi	sp,sp,16
ffffffffc0200228:	8082                	ret

ffffffffc020022a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020022a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	00005517          	auipc	a0,0x5
ffffffffc0200230:	6ac50513          	addi	a0,a0,1708 # ffffffffc02058d8 <etext+0x30>
void print_kerninfo(void) {
ffffffffc0200234:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200236:	f63ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020023a:	00000597          	auipc	a1,0x0
ffffffffc020023e:	e1058593          	addi	a1,a1,-496 # ffffffffc020004a <kern_init>
ffffffffc0200242:	00005517          	auipc	a0,0x5
ffffffffc0200246:	6b650513          	addi	a0,a0,1718 # ffffffffc02058f8 <etext+0x50>
ffffffffc020024a:	f4fff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024e:	00005597          	auipc	a1,0x5
ffffffffc0200252:	65a58593          	addi	a1,a1,1626 # ffffffffc02058a8 <etext>
ffffffffc0200256:	00005517          	auipc	a0,0x5
ffffffffc020025a:	6c250513          	addi	a0,a0,1730 # ffffffffc0205918 <etext+0x70>
ffffffffc020025e:	f3bff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200262:	000b1597          	auipc	a1,0xb1
ffffffffc0200266:	f8658593          	addi	a1,a1,-122 # ffffffffc02b11e8 <buf>
ffffffffc020026a:	00005517          	auipc	a0,0x5
ffffffffc020026e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0205938 <etext+0x90>
ffffffffc0200272:	f27ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200276:	000b5597          	auipc	a1,0xb5
ffffffffc020027a:	45258593          	addi	a1,a1,1106 # ffffffffc02b56c8 <end>
ffffffffc020027e:	00005517          	auipc	a0,0x5
ffffffffc0200282:	6da50513          	addi	a0,a0,1754 # ffffffffc0205958 <etext+0xb0>
ffffffffc0200286:	f13ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020028a:	00000717          	auipc	a4,0x0
ffffffffc020028e:	dc070713          	addi	a4,a4,-576 # ffffffffc020004a <kern_init>
ffffffffc0200292:	000b6797          	auipc	a5,0xb6
ffffffffc0200296:	83578793          	addi	a5,a5,-1995 # ffffffffc02b5ac7 <end+0x3ff>
ffffffffc020029a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02002a0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a6:	95be                	add	a1,a1,a5
ffffffffc02002a8:	85a9                	srai	a1,a1,0xa
ffffffffc02002aa:	00005517          	auipc	a0,0x5
ffffffffc02002ae:	6ce50513          	addi	a0,a0,1742 # ffffffffc0205978 <etext+0xd0>
}
ffffffffc02002b2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b4:	b5d5                	j	ffffffffc0200198 <cprintf>

ffffffffc02002b6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002b6:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b8:	00005617          	auipc	a2,0x5
ffffffffc02002bc:	6f060613          	addi	a2,a2,1776 # ffffffffc02059a8 <etext+0x100>
ffffffffc02002c0:	04d00593          	li	a1,77
ffffffffc02002c4:	00005517          	auipc	a0,0x5
ffffffffc02002c8:	6fc50513          	addi	a0,a0,1788 # ffffffffc02059c0 <etext+0x118>
void print_stackframe(void) {
ffffffffc02002cc:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ce:	17c000ef          	jal	ffffffffc020044a <__panic>

ffffffffc02002d2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002d2:	1101                	addi	sp,sp,-32
ffffffffc02002d4:	e822                	sd	s0,16(sp)
ffffffffc02002d6:	e426                	sd	s1,8(sp)
ffffffffc02002d8:	ec06                	sd	ra,24(sp)
ffffffffc02002da:	00007417          	auipc	s0,0x7
ffffffffc02002de:	32e40413          	addi	s0,s0,814 # ffffffffc0207608 <commands>
ffffffffc02002e2:	00007497          	auipc	s1,0x7
ffffffffc02002e6:	36e48493          	addi	s1,s1,878 # ffffffffc0207650 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ea:	6410                	ld	a2,8(s0)
ffffffffc02002ec:	600c                	ld	a1,0(s0)
ffffffffc02002ee:	00005517          	auipc	a0,0x5
ffffffffc02002f2:	6ea50513          	addi	a0,a0,1770 # ffffffffc02059d8 <etext+0x130>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002f8:	ea1ff0ef          	jal	ffffffffc0200198 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fc:	fe9417e3          	bne	s0,s1,ffffffffc02002ea <mon_help+0x18>
    }
    return 0;
}
ffffffffc0200300:	60e2                	ld	ra,24(sp)
ffffffffc0200302:	6442                	ld	s0,16(sp)
ffffffffc0200304:	64a2                	ld	s1,8(sp)
ffffffffc0200306:	4501                	li	a0,0
ffffffffc0200308:	6105                	addi	sp,sp,32
ffffffffc020030a:	8082                	ret

ffffffffc020030c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020030c:	1141                	addi	sp,sp,-16
ffffffffc020030e:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200310:	f1bff0ef          	jal	ffffffffc020022a <print_kerninfo>
    return 0;
}
ffffffffc0200314:	60a2                	ld	ra,8(sp)
ffffffffc0200316:	4501                	li	a0,0
ffffffffc0200318:	0141                	addi	sp,sp,16
ffffffffc020031a:	8082                	ret

ffffffffc020031c <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020031c:	1141                	addi	sp,sp,-16
ffffffffc020031e:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200320:	f97ff0ef          	jal	ffffffffc02002b6 <print_stackframe>
    return 0;
}
ffffffffc0200324:	60a2                	ld	ra,8(sp)
ffffffffc0200326:	4501                	li	a0,0
ffffffffc0200328:	0141                	addi	sp,sp,16
ffffffffc020032a:	8082                	ret

ffffffffc020032c <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020032c:	7131                	addi	sp,sp,-192
ffffffffc020032e:	e952                	sd	s4,144(sp)
ffffffffc0200330:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200332:	00005517          	auipc	a0,0x5
ffffffffc0200336:	6b650513          	addi	a0,a0,1718 # ffffffffc02059e8 <etext+0x140>
kmonitor(struct trapframe *tf) {
ffffffffc020033a:	fd06                	sd	ra,184(sp)
ffffffffc020033c:	f922                	sd	s0,176(sp)
ffffffffc020033e:	f526                	sd	s1,168(sp)
ffffffffc0200340:	ed4e                	sd	s3,152(sp)
ffffffffc0200342:	e556                	sd	s5,136(sp)
ffffffffc0200344:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200346:	e53ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020034a:	00005517          	auipc	a0,0x5
ffffffffc020034e:	6c650513          	addi	a0,a0,1734 # ffffffffc0205a10 <etext+0x168>
ffffffffc0200352:	e47ff0ef          	jal	ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc0200356:	000a0563          	beqz	s4,ffffffffc0200360 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020035a:	8552                	mv	a0,s4
ffffffffc020035c:	792000ef          	jal	ffffffffc0200aee <print_trapframe>
ffffffffc0200360:	00007a97          	auipc	s5,0x7
ffffffffc0200364:	2a8a8a93          	addi	s5,s5,680 # ffffffffc0207608 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020036a:	00005517          	auipc	a0,0x5
ffffffffc020036e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0205a38 <etext+0x190>
ffffffffc0200372:	d39ff0ef          	jal	ffffffffc02000aa <readline>
ffffffffc0200376:	842a                	mv	s0,a0
ffffffffc0200378:	d96d                	beqz	a0,ffffffffc020036a <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037a:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037e:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200380:	e99d                	bnez	a1,ffffffffc02003b6 <kmonitor+0x8a>
    int argc = 0;
ffffffffc0200382:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc0200384:	fe0b03e3          	beqz	s6,ffffffffc020036a <kmonitor+0x3e>
ffffffffc0200388:	00007497          	auipc	s1,0x7
ffffffffc020038c:	28048493          	addi	s1,s1,640 # ffffffffc0207608 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200390:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	6088                	ld	a0,0(s1)
ffffffffc0200396:	47a050ef          	jal	ffffffffc0205810 <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039a:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020039c:	c149                	beqz	a0,ffffffffc020041e <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	2405                	addiw	s0,s0,1
ffffffffc02003a0:	04e1                	addi	s1,s1,24
ffffffffc02003a2:	fef418e3          	bne	s0,a5,ffffffffc0200392 <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a6:	6582                	ld	a1,0(sp)
ffffffffc02003a8:	00005517          	auipc	a0,0x5
ffffffffc02003ac:	6c050513          	addi	a0,a0,1728 # ffffffffc0205a68 <etext+0x1c0>
ffffffffc02003b0:	de9ff0ef          	jal	ffffffffc0200198 <cprintf>
    return 0;
ffffffffc02003b4:	bf5d                	j	ffffffffc020036a <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b6:	00005517          	auipc	a0,0x5
ffffffffc02003ba:	68a50513          	addi	a0,a0,1674 # ffffffffc0205a40 <etext+0x198>
ffffffffc02003be:	4ae050ef          	jal	ffffffffc020586c <strchr>
ffffffffc02003c2:	c901                	beqz	a0,ffffffffc02003d2 <kmonitor+0xa6>
ffffffffc02003c4:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003c8:	00040023          	sb	zero,0(s0)
ffffffffc02003cc:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ce:	d9d5                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc02003d0:	b7dd                	j	ffffffffc02003b6 <kmonitor+0x8a>
        if (*buf == '\0') {
ffffffffc02003d2:	00044783          	lbu	a5,0(s0)
ffffffffc02003d6:	d7d5                	beqz	a5,ffffffffc0200382 <kmonitor+0x56>
        if (argc == MAXARGS - 1) {
ffffffffc02003d8:	03348b63          	beq	s1,s3,ffffffffc020040e <kmonitor+0xe2>
        argv[argc ++] = buf;
ffffffffc02003dc:	00349793          	slli	a5,s1,0x3
ffffffffc02003e0:	978a                	add	a5,a5,sp
ffffffffc02003e2:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003e4:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003e8:	2485                	addiw	s1,s1,1
ffffffffc02003ea:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ec:	e591                	bnez	a1,ffffffffc02003f8 <kmonitor+0xcc>
ffffffffc02003ee:	bf59                	j	ffffffffc0200384 <kmonitor+0x58>
ffffffffc02003f0:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003f4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f6:	d5d1                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc02003f8:	00005517          	auipc	a0,0x5
ffffffffc02003fc:	64850513          	addi	a0,a0,1608 # ffffffffc0205a40 <etext+0x198>
ffffffffc0200400:	46c050ef          	jal	ffffffffc020586c <strchr>
ffffffffc0200404:	d575                	beqz	a0,ffffffffc02003f0 <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200406:	00044583          	lbu	a1,0(s0)
ffffffffc020040a:	dda5                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc020040c:	b76d                	j	ffffffffc02003b6 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040e:	45c1                	li	a1,16
ffffffffc0200410:	00005517          	auipc	a0,0x5
ffffffffc0200414:	63850513          	addi	a0,a0,1592 # ffffffffc0205a48 <etext+0x1a0>
ffffffffc0200418:	d81ff0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc020041c:	b7c1                	j	ffffffffc02003dc <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041e:	00141793          	slli	a5,s0,0x1
ffffffffc0200422:	97a2                	add	a5,a5,s0
ffffffffc0200424:	078e                	slli	a5,a5,0x3
ffffffffc0200426:	97d6                	add	a5,a5,s5
ffffffffc0200428:	6b9c                	ld	a5,16(a5)
ffffffffc020042a:	fffb051b          	addiw	a0,s6,-1
ffffffffc020042e:	8652                	mv	a2,s4
ffffffffc0200430:	002c                	addi	a1,sp,8
ffffffffc0200432:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200434:	f2055be3          	bgez	a0,ffffffffc020036a <kmonitor+0x3e>
}
ffffffffc0200438:	70ea                	ld	ra,184(sp)
ffffffffc020043a:	744a                	ld	s0,176(sp)
ffffffffc020043c:	74aa                	ld	s1,168(sp)
ffffffffc020043e:	69ea                	ld	s3,152(sp)
ffffffffc0200440:	6a4a                	ld	s4,144(sp)
ffffffffc0200442:	6aaa                	ld	s5,136(sp)
ffffffffc0200444:	6b0a                	ld	s6,128(sp)
ffffffffc0200446:	6129                	addi	sp,sp,192
ffffffffc0200448:	8082                	ret

ffffffffc020044a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020044a:	000b5317          	auipc	t1,0xb5
ffffffffc020044e:	1f633303          	ld	t1,502(t1) # ffffffffc02b5640 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200452:	715d                	addi	sp,sp,-80
ffffffffc0200454:	ec06                	sd	ra,24(sp)
ffffffffc0200456:	f436                	sd	a3,40(sp)
ffffffffc0200458:	f83a                	sd	a4,48(sp)
ffffffffc020045a:	fc3e                	sd	a5,56(sp)
ffffffffc020045c:	e0c2                	sd	a6,64(sp)
ffffffffc020045e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200460:	02031e63          	bnez	t1,ffffffffc020049c <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200464:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200466:	103c                	addi	a5,sp,40
ffffffffc0200468:	e822                	sd	s0,16(sp)
ffffffffc020046a:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020046c:	862e                	mv	a2,a1
ffffffffc020046e:	85aa                	mv	a1,a0
ffffffffc0200470:	00005517          	auipc	a0,0x5
ffffffffc0200474:	6a050513          	addi	a0,a0,1696 # ffffffffc0205b10 <etext+0x268>
    is_panic = 1;
ffffffffc0200478:	000b5697          	auipc	a3,0xb5
ffffffffc020047c:	1ce6b423          	sd	a4,456(a3) # ffffffffc02b5640 <is_panic>
    va_start(ap, fmt);
ffffffffc0200480:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200482:	d17ff0ef          	jal	ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200486:	65a2                	ld	a1,8(sp)
ffffffffc0200488:	8522                	mv	a0,s0
ffffffffc020048a:	cefff0ef          	jal	ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc020048e:	00005517          	auipc	a0,0x5
ffffffffc0200492:	6a250513          	addi	a0,a0,1698 # ffffffffc0205b30 <etext+0x288>
ffffffffc0200496:	d03ff0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc020049a:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020049c:	4501                	li	a0,0
ffffffffc020049e:	4581                	li	a1,0
ffffffffc02004a0:	4601                	li	a2,0
ffffffffc02004a2:	48a1                	li	a7,8
ffffffffc02004a4:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004a8:	456000ef          	jal	ffffffffc02008fe <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ac:	4501                	li	a0,0
ffffffffc02004ae:	e7fff0ef          	jal	ffffffffc020032c <kmonitor>
    while (1) {
ffffffffc02004b2:	bfed                	j	ffffffffc02004ac <__panic+0x62>

ffffffffc02004b4 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004b4:	715d                	addi	sp,sp,-80
ffffffffc02004b6:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b8:	02810313          	addi	t1,sp,40
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004bc:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004be:	862e                	mv	a2,a1
ffffffffc02004c0:	85aa                	mv	a1,a0
ffffffffc02004c2:	00005517          	auipc	a0,0x5
ffffffffc02004c6:	67650513          	addi	a0,a0,1654 # ffffffffc0205b38 <etext+0x290>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004ca:	ec06                	sd	ra,24(sp)
ffffffffc02004cc:	f436                	sd	a3,40(sp)
ffffffffc02004ce:	f83a                	sd	a4,48(sp)
ffffffffc02004d0:	fc3e                	sd	a5,56(sp)
ffffffffc02004d2:	e0c2                	sd	a6,64(sp)
ffffffffc02004d4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004d6:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004d8:	cc1ff0ef          	jal	ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004dc:	65a2                	ld	a1,8(sp)
ffffffffc02004de:	8522                	mv	a0,s0
ffffffffc02004e0:	c99ff0ef          	jal	ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004e4:	00005517          	auipc	a0,0x5
ffffffffc02004e8:	64c50513          	addi	a0,a0,1612 # ffffffffc0205b30 <etext+0x288>
ffffffffc02004ec:	cadff0ef          	jal	ffffffffc0200198 <cprintf>
    va_end(ap);
}
ffffffffc02004f0:	60e2                	ld	ra,24(sp)
ffffffffc02004f2:	6442                	ld	s0,16(sp)
ffffffffc02004f4:	6161                	addi	sp,sp,80
ffffffffc02004f6:	8082                	ret

ffffffffc02004f8 <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc02004f8:	02000793          	li	a5,32
ffffffffc02004fc:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200500:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200504:	67e1                	lui	a5,0x18
ffffffffc0200506:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xd160>
ffffffffc020050a:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020050c:	4581                	li	a1,0
ffffffffc020050e:	4601                	li	a2,0
ffffffffc0200510:	4881                	li	a7,0
ffffffffc0200512:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc0200516:	00005517          	auipc	a0,0x5
ffffffffc020051a:	64250513          	addi	a0,a0,1602 # ffffffffc0205b58 <etext+0x2b0>
    ticks = 0;
ffffffffc020051e:	000b5797          	auipc	a5,0xb5
ffffffffc0200522:	1207b523          	sd	zero,298(a5) # ffffffffc02b5648 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200526:	b98d                	j	ffffffffc0200198 <cprintf>

ffffffffc0200528 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200528:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020052c:	67e1                	lui	a5,0x18
ffffffffc020052e:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xd160>
ffffffffc0200532:	953e                	add	a0,a0,a5
ffffffffc0200534:	4581                	li	a1,0
ffffffffc0200536:	4601                	li	a2,0
ffffffffc0200538:	4881                	li	a7,0
ffffffffc020053a:	00000073          	ecall
ffffffffc020053e:	8082                	ret

ffffffffc0200540 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200540:	8082                	ret

ffffffffc0200542 <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200542:	100027f3          	csrr	a5,sstatus
ffffffffc0200546:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200548:	0ff57513          	zext.b	a0,a0
ffffffffc020054c:	e799                	bnez	a5,ffffffffc020055a <cons_putc+0x18>
ffffffffc020054e:	4581                	li	a1,0
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4885                	li	a7,1
ffffffffc0200554:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc0200558:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc020055a:	1101                	addi	sp,sp,-32
ffffffffc020055c:	ec06                	sd	ra,24(sp)
ffffffffc020055e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200560:	39e000ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0200564:	6522                	ld	a0,8(sp)
ffffffffc0200566:	4581                	li	a1,0
ffffffffc0200568:	4601                	li	a2,0
ffffffffc020056a:	4885                	li	a7,1
ffffffffc020056c:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200570:	60e2                	ld	ra,24(sp)
ffffffffc0200572:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc0200574:	a651                	j	ffffffffc02008f8 <intr_enable>

ffffffffc0200576 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200576:	100027f3          	csrr	a5,sstatus
ffffffffc020057a:	8b89                	andi	a5,a5,2
ffffffffc020057c:	eb89                	bnez	a5,ffffffffc020058e <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020057e:	4501                	li	a0,0
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4889                	li	a7,2
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020058c:	8082                	ret
int cons_getc(void) {
ffffffffc020058e:	1101                	addi	sp,sp,-32
ffffffffc0200590:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200592:	36c000ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0200596:	4501                	li	a0,0
ffffffffc0200598:	4581                	li	a1,0
ffffffffc020059a:	4601                	li	a2,0
ffffffffc020059c:	4889                	li	a7,2
ffffffffc020059e:	00000073          	ecall
ffffffffc02005a2:	2501                	sext.w	a0,a0
ffffffffc02005a4:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005a6:	352000ef          	jal	ffffffffc02008f8 <intr_enable>
}
ffffffffc02005aa:	60e2                	ld	ra,24(sp)
ffffffffc02005ac:	6522                	ld	a0,8(sp)
ffffffffc02005ae:	6105                	addi	sp,sp,32
ffffffffc02005b0:	8082                	ret

ffffffffc02005b2 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005b2:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc02005b4:	00005517          	auipc	a0,0x5
ffffffffc02005b8:	5c450513          	addi	a0,a0,1476 # ffffffffc0205b78 <etext+0x2d0>
void dtb_init(void) {
ffffffffc02005bc:	f406                	sd	ra,40(sp)
ffffffffc02005be:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c0:	bd9ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005c4:	0000c597          	auipc	a1,0xc
ffffffffc02005c8:	a3c5b583          	ld	a1,-1476(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc02005cc:	00005517          	auipc	a0,0x5
ffffffffc02005d0:	5bc50513          	addi	a0,a0,1468 # ffffffffc0205b88 <etext+0x2e0>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005d4:	0000c417          	auipc	s0,0xc
ffffffffc02005d8:	a3440413          	addi	s0,s0,-1484 # ffffffffc020c008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005dc:	bbdff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e0:	600c                	ld	a1,0(s0)
ffffffffc02005e2:	00005517          	auipc	a0,0x5
ffffffffc02005e6:	5b650513          	addi	a0,a0,1462 # ffffffffc0205b98 <etext+0x2f0>
ffffffffc02005ea:	bafff0ef          	jal	ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005ee:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f0:	00005517          	auipc	a0,0x5
ffffffffc02005f4:	5c050513          	addi	a0,a0,1472 # ffffffffc0205bb0 <etext+0x308>
    if (boot_dtb == 0) {
ffffffffc02005f8:	10070163          	beqz	a4,ffffffffc02006fa <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005fc:	57f5                	li	a5,-3
ffffffffc02005fe:	07fa                	slli	a5,a5,0x1e
ffffffffc0200600:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200602:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc0200604:	d00e06b7          	lui	a3,0xd00e0
ffffffffc0200608:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfe2a825>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020060c:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200610:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200614:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200618:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061c:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200620:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200622:	8e49                	or	a2,a2,a0
ffffffffc0200624:	0ff7f793          	zext.b	a5,a5
ffffffffc0200628:	8dd1                	or	a1,a1,a2
ffffffffc020062a:	07a2                	slli	a5,a5,0x8
ffffffffc020062c:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020062e:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200632:	0cd59863          	bne	a1,a3,ffffffffc0200702 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200636:	4710                	lw	a2,8(a4)
ffffffffc0200638:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020063a:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063c:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200640:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200644:	01865e1b          	srliw	t3,a2,0x18
ffffffffc0200648:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064c:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200650:	0186959b          	slliw	a1,a3,0x18
ffffffffc0200654:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200658:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200660:	0106d69b          	srliw	a3,a3,0x10
ffffffffc0200664:	01c56533          	or	a0,a0,t3
ffffffffc0200668:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200670:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200674:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0ff6f693          	zext.b	a3,a3
ffffffffc020067c:	8c49                	or	s0,s0,a0
ffffffffc020067e:	0622                	slli	a2,a2,0x8
ffffffffc0200680:	8fcd                	or	a5,a5,a1
ffffffffc0200682:	06a2                	slli	a3,a3,0x8
ffffffffc0200684:	8c51                	or	s0,s0,a2
ffffffffc0200686:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200688:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020068a:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020068c:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020068e:	9381                	srli	a5,a5,0x20
ffffffffc0200690:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200692:	4301                	li	t1,0
        switch (token) {
ffffffffc0200694:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200696:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200698:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc020069c:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020069e:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006a4:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a8:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ac:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	8ed1                	or	a3,a3,a2
ffffffffc02006ba:	0ff77713          	zext.b	a4,a4
ffffffffc02006be:	8fd5                	or	a5,a5,a3
ffffffffc02006c0:	0722                	slli	a4,a4,0x8
ffffffffc02006c2:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc02006c4:	05178763          	beq	a5,a7,ffffffffc0200712 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006c8:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02006ca:	00f8e963          	bltu	a7,a5,ffffffffc02006dc <dtb_init+0x12a>
ffffffffc02006ce:	07c78d63          	beq	a5,t3,ffffffffc0200748 <dtb_init+0x196>
ffffffffc02006d2:	4709                	li	a4,2
ffffffffc02006d4:	00e79763          	bne	a5,a4,ffffffffc02006e2 <dtb_init+0x130>
ffffffffc02006d8:	4301                	li	t1,0
ffffffffc02006da:	b7d1                	j	ffffffffc020069e <dtb_init+0xec>
ffffffffc02006dc:	4711                	li	a4,4
ffffffffc02006de:	fce780e3          	beq	a5,a4,ffffffffc020069e <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006e2:	00005517          	auipc	a0,0x5
ffffffffc02006e6:	59650513          	addi	a0,a0,1430 # ffffffffc0205c78 <etext+0x3d0>
ffffffffc02006ea:	aafff0ef          	jal	ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006ee:	64e2                	ld	s1,24(sp)
ffffffffc02006f0:	6942                	ld	s2,16(sp)
ffffffffc02006f2:	00005517          	auipc	a0,0x5
ffffffffc02006f6:	5be50513          	addi	a0,a0,1470 # ffffffffc0205cb0 <etext+0x408>
}
ffffffffc02006fa:	7402                	ld	s0,32(sp)
ffffffffc02006fc:	70a2                	ld	ra,40(sp)
ffffffffc02006fe:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200700:	bc61                	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200702:	7402                	ld	s0,32(sp)
ffffffffc0200704:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200706:	00005517          	auipc	a0,0x5
ffffffffc020070a:	4ca50513          	addi	a0,a0,1226 # ffffffffc0205bd0 <etext+0x328>
}
ffffffffc020070e:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200710:	b461                	j	ffffffffc0200198 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200712:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200714:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200718:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200720:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200724:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200728:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072c:	8ed1                	or	a3,a3,a2
ffffffffc020072e:	0ff77713          	zext.b	a4,a4
ffffffffc0200732:	8fd5                	or	a5,a5,a3
ffffffffc0200734:	0722                	slli	a4,a4,0x8
ffffffffc0200736:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200738:	04031463          	bnez	t1,ffffffffc0200780 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020073c:	1782                	slli	a5,a5,0x20
ffffffffc020073e:	9381                	srli	a5,a5,0x20
ffffffffc0200740:	043d                	addi	s0,s0,15
ffffffffc0200742:	943e                	add	s0,s0,a5
ffffffffc0200744:	9871                	andi	s0,s0,-4
                break;
ffffffffc0200746:	bfa1                	j	ffffffffc020069e <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc0200748:	8522                	mv	a0,s0
ffffffffc020074a:	e01a                	sd	t1,0(sp)
ffffffffc020074c:	07e050ef          	jal	ffffffffc02057ca <strlen>
ffffffffc0200750:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200752:	4619                	li	a2,6
ffffffffc0200754:	8522                	mv	a0,s0
ffffffffc0200756:	00005597          	auipc	a1,0x5
ffffffffc020075a:	4a258593          	addi	a1,a1,1186 # ffffffffc0205bf8 <etext+0x350>
ffffffffc020075e:	0e6050ef          	jal	ffffffffc0205844 <strncmp>
ffffffffc0200762:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200764:	0411                	addi	s0,s0,4
ffffffffc0200766:	0004879b          	sext.w	a5,s1
ffffffffc020076a:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020076c:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200770:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200772:	00a36333          	or	t1,t1,a0
                break;
ffffffffc0200776:	00ff0837          	lui	a6,0xff0
ffffffffc020077a:	488d                	li	a7,3
ffffffffc020077c:	4e05                	li	t3,1
ffffffffc020077e:	b705                	j	ffffffffc020069e <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200780:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200782:	00005597          	auipc	a1,0x5
ffffffffc0200786:	47e58593          	addi	a1,a1,1150 # ffffffffc0205c00 <etext+0x358>
ffffffffc020078a:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020078c:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200790:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200794:	0187169b          	slliw	a3,a4,0x18
ffffffffc0200798:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020079c:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a0:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a4:	8ed1                	or	a3,a3,a2
ffffffffc02007a6:	0ff77713          	zext.b	a4,a4
ffffffffc02007aa:	0722                	slli	a4,a4,0x8
ffffffffc02007ac:	8d55                	or	a0,a0,a3
ffffffffc02007ae:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007b0:	1502                	slli	a0,a0,0x20
ffffffffc02007b2:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007b4:	954a                	add	a0,a0,s2
ffffffffc02007b6:	e01a                	sd	t1,0(sp)
ffffffffc02007b8:	058050ef          	jal	ffffffffc0205810 <strcmp>
ffffffffc02007bc:	67a2                	ld	a5,8(sp)
ffffffffc02007be:	473d                	li	a4,15
ffffffffc02007c0:	6302                	ld	t1,0(sp)
ffffffffc02007c2:	00ff0837          	lui	a6,0xff0
ffffffffc02007c6:	488d                	li	a7,3
ffffffffc02007c8:	4e05                	li	t3,1
ffffffffc02007ca:	f6f779e3          	bgeu	a4,a5,ffffffffc020073c <dtb_init+0x18a>
ffffffffc02007ce:	f53d                	bnez	a0,ffffffffc020073c <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007d0:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007d4:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007d8:	00005517          	auipc	a0,0x5
ffffffffc02007dc:	43050513          	addi	a0,a0,1072 # ffffffffc0205c08 <etext+0x360>
           fdt32_to_cpu(x >> 32);
ffffffffc02007e0:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007e4:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02007e8:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007ec:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f0:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0187959b          	slliw	a1,a5,0x18
ffffffffc02007f8:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200808:	01037333          	and	t1,t1,a6
ffffffffc020080c:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	01e5e5b3          	or	a1,a1,t5
ffffffffc0200814:	0ff7f793          	zext.b	a5,a5
ffffffffc0200818:	01de6e33          	or	t3,t3,t4
ffffffffc020081c:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200820:	01067633          	and	a2,a2,a6
ffffffffc0200824:	0086d31b          	srliw	t1,a3,0x8
ffffffffc0200828:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020082c:	07a2                	slli	a5,a5,0x8
ffffffffc020082e:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200832:	0186df1b          	srliw	t5,a3,0x18
ffffffffc0200836:	01875e9b          	srliw	t4,a4,0x18
ffffffffc020083a:	8ddd                	or	a1,a1,a5
ffffffffc020083c:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200840:	0186979b          	slliw	a5,a3,0x18
ffffffffc0200844:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200848:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200850:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200854:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200858:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085c:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200860:	08a2                	slli	a7,a7,0x8
ffffffffc0200862:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200866:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020086a:	0ff6f693          	zext.b	a3,a3
ffffffffc020086e:	01de6833          	or	a6,t3,t4
ffffffffc0200872:	0ff77713          	zext.b	a4,a4
ffffffffc0200876:	01166633          	or	a2,a2,a7
ffffffffc020087a:	0067e7b3          	or	a5,a5,t1
ffffffffc020087e:	06a2                	slli	a3,a3,0x8
ffffffffc0200880:	01046433          	or	s0,s0,a6
ffffffffc0200884:	0722                	slli	a4,a4,0x8
ffffffffc0200886:	8fd5                	or	a5,a5,a3
ffffffffc0200888:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	1582                	slli	a1,a1,0x20
ffffffffc020088c:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020088e:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200890:	9201                	srli	a2,a2,0x20
ffffffffc0200892:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200894:	1402                	slli	s0,s0,0x20
ffffffffc0200896:	00b7e4b3          	or	s1,a5,a1
ffffffffc020089a:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc020089c:	8fdff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008a0:	85a6                	mv	a1,s1
ffffffffc02008a2:	00005517          	auipc	a0,0x5
ffffffffc02008a6:	38650513          	addi	a0,a0,902 # ffffffffc0205c28 <etext+0x380>
ffffffffc02008aa:	8efff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008ae:	01445613          	srli	a2,s0,0x14
ffffffffc02008b2:	85a2                	mv	a1,s0
ffffffffc02008b4:	00005517          	auipc	a0,0x5
ffffffffc02008b8:	38c50513          	addi	a0,a0,908 # ffffffffc0205c40 <etext+0x398>
ffffffffc02008bc:	8ddff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c0:	009405b3          	add	a1,s0,s1
ffffffffc02008c4:	15fd                	addi	a1,a1,-1
ffffffffc02008c6:	00005517          	auipc	a0,0x5
ffffffffc02008ca:	39a50513          	addi	a0,a0,922 # ffffffffc0205c60 <etext+0x3b8>
ffffffffc02008ce:	8cbff0ef          	jal	ffffffffc0200198 <cprintf>
        memory_base = mem_base;
ffffffffc02008d2:	000b5797          	auipc	a5,0xb5
ffffffffc02008d6:	d897b323          	sd	s1,-634(a5) # ffffffffc02b5658 <memory_base>
        memory_size = mem_size;
ffffffffc02008da:	000b5797          	auipc	a5,0xb5
ffffffffc02008de:	d687bb23          	sd	s0,-650(a5) # ffffffffc02b5650 <memory_size>
ffffffffc02008e2:	b531                	j	ffffffffc02006ee <dtb_init+0x13c>

ffffffffc02008e4 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008e4:	000b5517          	auipc	a0,0xb5
ffffffffc02008e8:	d7453503          	ld	a0,-652(a0) # ffffffffc02b5658 <memory_base>
ffffffffc02008ec:	8082                	ret

ffffffffc02008ee <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008ee:	000b5517          	auipc	a0,0xb5
ffffffffc02008f2:	d6253503          	ld	a0,-670(a0) # ffffffffc02b5650 <memory_size>
ffffffffc02008f6:	8082                	ret

ffffffffc02008f8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008f8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02008fc:	8082                	ret

ffffffffc02008fe <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008fe:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200902:	8082                	ret

ffffffffc0200904 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200904:	8082                	ret

ffffffffc0200906 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200906:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020090a:	00000797          	auipc	a5,0x0
ffffffffc020090e:	4b678793          	addi	a5,a5,1206 # ffffffffc0200dc0 <__alltraps>
ffffffffc0200912:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200916:	000407b7          	lui	a5,0x40
ffffffffc020091a:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200920:	610c                	ld	a1,0(a0)
{
ffffffffc0200922:	1141                	addi	sp,sp,-16
ffffffffc0200924:	e022                	sd	s0,0(sp)
ffffffffc0200926:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200928:	00005517          	auipc	a0,0x5
ffffffffc020092c:	3a050513          	addi	a0,a0,928 # ffffffffc0205cc8 <etext+0x420>
{
ffffffffc0200930:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200932:	867ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200936:	640c                	ld	a1,8(s0)
ffffffffc0200938:	00005517          	auipc	a0,0x5
ffffffffc020093c:	3a850513          	addi	a0,a0,936 # ffffffffc0205ce0 <etext+0x438>
ffffffffc0200940:	859ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200944:	680c                	ld	a1,16(s0)
ffffffffc0200946:	00005517          	auipc	a0,0x5
ffffffffc020094a:	3b250513          	addi	a0,a0,946 # ffffffffc0205cf8 <etext+0x450>
ffffffffc020094e:	84bff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200952:	6c0c                	ld	a1,24(s0)
ffffffffc0200954:	00005517          	auipc	a0,0x5
ffffffffc0200958:	3bc50513          	addi	a0,a0,956 # ffffffffc0205d10 <etext+0x468>
ffffffffc020095c:	83dff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200960:	700c                	ld	a1,32(s0)
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	3c650513          	addi	a0,a0,966 # ffffffffc0205d28 <etext+0x480>
ffffffffc020096a:	82fff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020096e:	740c                	ld	a1,40(s0)
ffffffffc0200970:	00005517          	auipc	a0,0x5
ffffffffc0200974:	3d050513          	addi	a0,a0,976 # ffffffffc0205d40 <etext+0x498>
ffffffffc0200978:	821ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc020097c:	780c                	ld	a1,48(s0)
ffffffffc020097e:	00005517          	auipc	a0,0x5
ffffffffc0200982:	3da50513          	addi	a0,a0,986 # ffffffffc0205d58 <etext+0x4b0>
ffffffffc0200986:	813ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020098a:	7c0c                	ld	a1,56(s0)
ffffffffc020098c:	00005517          	auipc	a0,0x5
ffffffffc0200990:	3e450513          	addi	a0,a0,996 # ffffffffc0205d70 <etext+0x4c8>
ffffffffc0200994:	805ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200998:	602c                	ld	a1,64(s0)
ffffffffc020099a:	00005517          	auipc	a0,0x5
ffffffffc020099e:	3ee50513          	addi	a0,a0,1006 # ffffffffc0205d88 <etext+0x4e0>
ffffffffc02009a2:	ff6ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009a6:	642c                	ld	a1,72(s0)
ffffffffc02009a8:	00005517          	auipc	a0,0x5
ffffffffc02009ac:	3f850513          	addi	a0,a0,1016 # ffffffffc0205da0 <etext+0x4f8>
ffffffffc02009b0:	fe8ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009b4:	682c                	ld	a1,80(s0)
ffffffffc02009b6:	00005517          	auipc	a0,0x5
ffffffffc02009ba:	40250513          	addi	a0,a0,1026 # ffffffffc0205db8 <etext+0x510>
ffffffffc02009be:	fdaff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c2:	6c2c                	ld	a1,88(s0)
ffffffffc02009c4:	00005517          	auipc	a0,0x5
ffffffffc02009c8:	40c50513          	addi	a0,a0,1036 # ffffffffc0205dd0 <etext+0x528>
ffffffffc02009cc:	fccff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d0:	702c                	ld	a1,96(s0)
ffffffffc02009d2:	00005517          	auipc	a0,0x5
ffffffffc02009d6:	41650513          	addi	a0,a0,1046 # ffffffffc0205de8 <etext+0x540>
ffffffffc02009da:	fbeff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009de:	742c                	ld	a1,104(s0)
ffffffffc02009e0:	00005517          	auipc	a0,0x5
ffffffffc02009e4:	42050513          	addi	a0,a0,1056 # ffffffffc0205e00 <etext+0x558>
ffffffffc02009e8:	fb0ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009ec:	782c                	ld	a1,112(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	42a50513          	addi	a0,a0,1066 # ffffffffc0205e18 <etext+0x570>
ffffffffc02009f6:	fa2ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02009fa:	7c2c                	ld	a1,120(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	43450513          	addi	a0,a0,1076 # ffffffffc0205e30 <etext+0x588>
ffffffffc0200a04:	f94ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a08:	604c                	ld	a1,128(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	43e50513          	addi	a0,a0,1086 # ffffffffc0205e48 <etext+0x5a0>
ffffffffc0200a12:	f86ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a16:	644c                	ld	a1,136(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	44850513          	addi	a0,a0,1096 # ffffffffc0205e60 <etext+0x5b8>
ffffffffc0200a20:	f78ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a24:	684c                	ld	a1,144(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	45250513          	addi	a0,a0,1106 # ffffffffc0205e78 <etext+0x5d0>
ffffffffc0200a2e:	f6aff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a32:	6c4c                	ld	a1,152(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	45c50513          	addi	a0,a0,1116 # ffffffffc0205e90 <etext+0x5e8>
ffffffffc0200a3c:	f5cff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a40:	704c                	ld	a1,160(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	46650513          	addi	a0,a0,1126 # ffffffffc0205ea8 <etext+0x600>
ffffffffc0200a4a:	f4eff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a4e:	744c                	ld	a1,168(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	47050513          	addi	a0,a0,1136 # ffffffffc0205ec0 <etext+0x618>
ffffffffc0200a58:	f40ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a5c:	784c                	ld	a1,176(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	47a50513          	addi	a0,a0,1146 # ffffffffc0205ed8 <etext+0x630>
ffffffffc0200a66:	f32ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a6a:	7c4c                	ld	a1,184(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	48450513          	addi	a0,a0,1156 # ffffffffc0205ef0 <etext+0x648>
ffffffffc0200a74:	f24ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a78:	606c                	ld	a1,192(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	48e50513          	addi	a0,a0,1166 # ffffffffc0205f08 <etext+0x660>
ffffffffc0200a82:	f16ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a86:	646c                	ld	a1,200(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	49850513          	addi	a0,a0,1176 # ffffffffc0205f20 <etext+0x678>
ffffffffc0200a90:	f08ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a94:	686c                	ld	a1,208(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	4a250513          	addi	a0,a0,1186 # ffffffffc0205f38 <etext+0x690>
ffffffffc0200a9e:	efaff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa2:	6c6c                	ld	a1,216(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	4ac50513          	addi	a0,a0,1196 # ffffffffc0205f50 <etext+0x6a8>
ffffffffc0200aac:	eecff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab0:	706c                	ld	a1,224(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	4b650513          	addi	a0,a0,1206 # ffffffffc0205f68 <etext+0x6c0>
ffffffffc0200aba:	edeff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200abe:	746c                	ld	a1,232(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	4c050513          	addi	a0,a0,1216 # ffffffffc0205f80 <etext+0x6d8>
ffffffffc0200ac8:	ed0ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200acc:	786c                	ld	a1,240(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	4ca50513          	addi	a0,a0,1226 # ffffffffc0205f98 <etext+0x6f0>
ffffffffc0200ad6:	ec2ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ada:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200adc:	6402                	ld	s0,0(sp)
ffffffffc0200ade:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	00005517          	auipc	a0,0x5
ffffffffc0200ae4:	4d050513          	addi	a0,a0,1232 # ffffffffc0205fb0 <etext+0x708>
}
ffffffffc0200ae8:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200aea:	eaeff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200aee <print_trapframe>:
{
ffffffffc0200aee:	1141                	addi	sp,sp,-16
ffffffffc0200af0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af2:	85aa                	mv	a1,a0
{
ffffffffc0200af4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af6:	00005517          	auipc	a0,0x5
ffffffffc0200afa:	4d250513          	addi	a0,a0,1234 # ffffffffc0205fc8 <etext+0x720>
{
ffffffffc0200afe:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b00:	e98ff0ef          	jal	ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b04:	8522                	mv	a0,s0
ffffffffc0200b06:	e1bff0ef          	jal	ffffffffc0200920 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b0a:	10043583          	ld	a1,256(s0)
ffffffffc0200b0e:	00005517          	auipc	a0,0x5
ffffffffc0200b12:	4d250513          	addi	a0,a0,1234 # ffffffffc0205fe0 <etext+0x738>
ffffffffc0200b16:	e82ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b1a:	10843583          	ld	a1,264(s0)
ffffffffc0200b1e:	00005517          	auipc	a0,0x5
ffffffffc0200b22:	4da50513          	addi	a0,a0,1242 # ffffffffc0205ff8 <etext+0x750>
ffffffffc0200b26:	e72ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b2a:	11043583          	ld	a1,272(s0)
ffffffffc0200b2e:	00005517          	auipc	a0,0x5
ffffffffc0200b32:	4e250513          	addi	a0,a0,1250 # ffffffffc0206010 <etext+0x768>
ffffffffc0200b36:	e62ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b3a:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b3e:	6402                	ld	s0,0(sp)
ffffffffc0200b40:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b42:	00005517          	auipc	a0,0x5
ffffffffc0200b46:	4de50513          	addi	a0,a0,1246 # ffffffffc0206020 <etext+0x778>
}
ffffffffc0200b4a:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b4c:	e4cff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200b50 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200b50:	11853783          	ld	a5,280(a0)
ffffffffc0200b54:	472d                	li	a4,11
ffffffffc0200b56:	0786                	slli	a5,a5,0x1
ffffffffc0200b58:	8385                	srli	a5,a5,0x1
ffffffffc0200b5a:	0af76363          	bltu	a4,a5,ffffffffc0200c00 <interrupt_handler+0xb0>
ffffffffc0200b5e:	00007717          	auipc	a4,0x7
ffffffffc0200b62:	af270713          	addi	a4,a4,-1294 # ffffffffc0207650 <commands+0x48>
ffffffffc0200b66:	078a                	slli	a5,a5,0x2
ffffffffc0200b68:	97ba                	add	a5,a5,a4
ffffffffc0200b6a:	439c                	lw	a5,0(a5)
ffffffffc0200b6c:	97ba                	add	a5,a5,a4
ffffffffc0200b6e:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b70:	00005517          	auipc	a0,0x5
ffffffffc0200b74:	52850513          	addi	a0,a0,1320 # ffffffffc0206098 <etext+0x7f0>
ffffffffc0200b78:	e20ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b7c:	00005517          	auipc	a0,0x5
ffffffffc0200b80:	4fc50513          	addi	a0,a0,1276 # ffffffffc0206078 <etext+0x7d0>
ffffffffc0200b84:	e14ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b88:	00005517          	auipc	a0,0x5
ffffffffc0200b8c:	4b050513          	addi	a0,a0,1200 # ffffffffc0206038 <etext+0x790>
ffffffffc0200b90:	e08ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b94:	00005517          	auipc	a0,0x5
ffffffffc0200b98:	4c450513          	addi	a0,a0,1220 # ffffffffc0206058 <etext+0x7b0>
ffffffffc0200b9c:	dfcff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200ba0:	1141                	addi	sp,sp,-16
ffffffffc0200ba2:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        clock_set_next_event();
ffffffffc0200ba4:	985ff0ef          	jal	ffffffffc0200528 <clock_set_next_event>
        ticks++;
ffffffffc0200ba8:	000b5797          	auipc	a5,0xb5
ffffffffc0200bac:	aa078793          	addi	a5,a5,-1376 # ffffffffc02b5648 <ticks>
ffffffffc0200bb0:	6394                	ld	a3,0(a5)

        // Keep ticks monotonically increasing for gettime_msec().
        // Print every TICK_NUM ticks (lab3-style), but do NOT reset ticks
        // and do NOT shutdown early; lab6 user-mode tests need to finish.
        if (ticks % TICK_NUM == 0) {
ffffffffc0200bb2:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200bb6:	28f70713          	addi	a4,a4,655 # 28f5c28f <_binary_obj___user_matrix_out_size+0x28f50d4f>
        ticks++;
ffffffffc0200bba:	0685                	addi	a3,a3,1
ffffffffc0200bbc:	e394                	sd	a3,0(a5)
        if (ticks % TICK_NUM == 0) {
ffffffffc0200bbe:	6390                	ld	a2,0(a5)
ffffffffc0200bc0:	5c28f6b7          	lui	a3,0x5c28f
ffffffffc0200bc4:	1702                	slli	a4,a4,0x20
ffffffffc0200bc6:	5c368693          	addi	a3,a3,1475 # 5c28f5c3 <_binary_obj___user_matrix_out_size+0x5c284083>
ffffffffc0200bca:	00265793          	srli	a5,a2,0x2
ffffffffc0200bce:	9736                	add	a4,a4,a3
ffffffffc0200bd0:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200bd4:	06400593          	li	a1,100
ffffffffc0200bd8:	8389                	srli	a5,a5,0x2
ffffffffc0200bda:	02b787b3          	mul	a5,a5,a1
ffffffffc0200bde:	02f60563          	beq	a2,a5,ffffffffc0200c08 <interrupt_handler+0xb8>
            print_ticks();
        }

        // lab6: update LAB3 steps
        // Call scheduler tick handler on timer interrupt.
        if (current) {
ffffffffc0200be2:	000b5517          	auipc	a0,0xb5
ffffffffc0200be6:	abe53503          	ld	a0,-1346(a0) # ffffffffc02b56a0 <current>
ffffffffc0200bea:	cd01                	beqz	a0,ffffffffc0200c02 <interrupt_handler+0xb2>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bec:	60a2                	ld	ra,8(sp)
ffffffffc0200bee:	0141                	addi	sp,sp,16
            sched_class_proc_tick(current);
ffffffffc0200bf0:	4d20406f          	j	ffffffffc02050c2 <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bf4:	00005517          	auipc	a0,0x5
ffffffffc0200bf8:	4d450513          	addi	a0,a0,1236 # ffffffffc02060c8 <etext+0x820>
ffffffffc0200bfc:	d9cff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c00:	b5fd                	j	ffffffffc0200aee <print_trapframe>
}
ffffffffc0200c02:	60a2                	ld	ra,8(sp)
ffffffffc0200c04:	0141                	addi	sp,sp,16
ffffffffc0200c06:	8082                	ret
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c08:	00005517          	auipc	a0,0x5
ffffffffc0200c0c:	4b050513          	addi	a0,a0,1200 # ffffffffc02060b8 <etext+0x810>
ffffffffc0200c10:	d88ff0ef          	jal	ffffffffc0200198 <cprintf>
}
ffffffffc0200c14:	b7f9                	j	ffffffffc0200be2 <interrupt_handler+0x92>

ffffffffc0200c16 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c16:	11853783          	ld	a5,280(a0)
ffffffffc0200c1a:	473d                	li	a4,15
ffffffffc0200c1c:	10f76e63          	bltu	a4,a5,ffffffffc0200d38 <exception_handler+0x122>
ffffffffc0200c20:	00007717          	auipc	a4,0x7
ffffffffc0200c24:	a6070713          	addi	a4,a4,-1440 # ffffffffc0207680 <commands+0x78>
ffffffffc0200c28:	078a                	slli	a5,a5,0x2
ffffffffc0200c2a:	97ba                	add	a5,a5,a4
ffffffffc0200c2c:	439c                	lw	a5,0(a5)
{
ffffffffc0200c2e:	1101                	addi	sp,sp,-32
ffffffffc0200c30:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c32:	97ba                	add	a5,a5,a4
ffffffffc0200c34:	86aa                	mv	a3,a0
ffffffffc0200c36:	8782                	jr	a5
ffffffffc0200c38:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c3a:	00005517          	auipc	a0,0x5
ffffffffc0200c3e:	59650513          	addi	a0,a0,1430 # ffffffffc02061d0 <etext+0x928>
ffffffffc0200c42:	d56ff0ef          	jal	ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200c46:	66a2                	ld	a3,8(sp)
ffffffffc0200c48:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c4c:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200c4e:	0791                	addi	a5,a5,4
ffffffffc0200c50:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200c54:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200c56:	7140406f          	j	ffffffffc020536a <syscall>
}
ffffffffc0200c5a:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c5c:	00005517          	auipc	a0,0x5
ffffffffc0200c60:	59450513          	addi	a0,a0,1428 # ffffffffc02061f0 <etext+0x948>
}
ffffffffc0200c64:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c66:	d32ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c6a:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c6c:	00005517          	auipc	a0,0x5
ffffffffc0200c70:	5a450513          	addi	a0,a0,1444 # ffffffffc0206210 <etext+0x968>
}
ffffffffc0200c74:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200c76:	d22ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c7a:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200c7c:	00005517          	auipc	a0,0x5
ffffffffc0200c80:	5b450513          	addi	a0,a0,1460 # ffffffffc0206230 <etext+0x988>
}
ffffffffc0200c84:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200c86:	d12ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c8a:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200c8c:	00005517          	auipc	a0,0x5
ffffffffc0200c90:	5bc50513          	addi	a0,a0,1468 # ffffffffc0206248 <etext+0x9a0>
}
ffffffffc0200c94:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200c96:	d02ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c9a:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200c9c:	00005517          	auipc	a0,0x5
ffffffffc0200ca0:	5c450513          	addi	a0,a0,1476 # ffffffffc0206260 <etext+0x9b8>
}
ffffffffc0200ca4:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200ca6:	cf2ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200caa:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200cac:	00005517          	auipc	a0,0x5
ffffffffc0200cb0:	43c50513          	addi	a0,a0,1084 # ffffffffc02060e8 <etext+0x840>
}
ffffffffc0200cb4:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200cb6:	ce2ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cba:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200cbc:	00005517          	auipc	a0,0x5
ffffffffc0200cc0:	44c50513          	addi	a0,a0,1100 # ffffffffc0206108 <etext+0x860>
}
ffffffffc0200cc4:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200cc6:	cd2ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cca:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200ccc:	00005517          	auipc	a0,0x5
ffffffffc0200cd0:	45c50513          	addi	a0,a0,1116 # ffffffffc0206128 <etext+0x880>
}
ffffffffc0200cd4:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200cd6:	cc2ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cda:	60e2                	ld	ra,24(sp)
        cprintf("Breakpoint\n");
ffffffffc0200cdc:	00005517          	auipc	a0,0x5
ffffffffc0200ce0:	46450513          	addi	a0,a0,1124 # ffffffffc0206140 <etext+0x898>
}
ffffffffc0200ce4:	6105                	addi	sp,sp,32
        cprintf("Breakpoint\n");
ffffffffc0200ce6:	cb2ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cea:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200cec:	00005517          	auipc	a0,0x5
ffffffffc0200cf0:	46450513          	addi	a0,a0,1124 # ffffffffc0206150 <etext+0x8a8>
}
ffffffffc0200cf4:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200cf6:	ca2ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cfa:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200cfc:	00005517          	auipc	a0,0x5
ffffffffc0200d00:	47450513          	addi	a0,a0,1140 # ffffffffc0206170 <etext+0x8c8>
}
ffffffffc0200d04:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d06:	c92ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d0a:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d0c:	00005517          	auipc	a0,0x5
ffffffffc0200d10:	4ac50513          	addi	a0,a0,1196 # ffffffffc02061b8 <etext+0x910>
}
ffffffffc0200d14:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d16:	c82ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d1a:	60e2                	ld	ra,24(sp)
ffffffffc0200d1c:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d1e:	bbc1                	j	ffffffffc0200aee <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d20:	00005617          	auipc	a2,0x5
ffffffffc0200d24:	46860613          	addi	a2,a2,1128 # ffffffffc0206188 <etext+0x8e0>
ffffffffc0200d28:	0c300593          	li	a1,195
ffffffffc0200d2c:	00005517          	auipc	a0,0x5
ffffffffc0200d30:	47450513          	addi	a0,a0,1140 # ffffffffc02061a0 <etext+0x8f8>
ffffffffc0200d34:	f16ff0ef          	jal	ffffffffc020044a <__panic>
        print_trapframe(tf);
ffffffffc0200d38:	bb5d                	j	ffffffffc0200aee <print_trapframe>

ffffffffc0200d3a <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d3a:	000b5717          	auipc	a4,0xb5
ffffffffc0200d3e:	96673703          	ld	a4,-1690(a4) # ffffffffc02b56a0 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d42:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d46:	cf21                	beqz	a4,ffffffffc0200d9e <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d48:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d4c:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200d50:	1101                	addi	sp,sp,-32
ffffffffc0200d52:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d54:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200d58:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d5a:	e432                	sd	a2,8(sp)
ffffffffc0200d5c:	e042                	sd	a6,0(sp)
ffffffffc0200d5e:	0205c763          	bltz	a1,ffffffffc0200d8c <trap+0x52>
        exception_handler(tf);
ffffffffc0200d62:	eb5ff0ef          	jal	ffffffffc0200c16 <exception_handler>
ffffffffc0200d66:	6622                	ld	a2,8(sp)
ffffffffc0200d68:	6802                	ld	a6,0(sp)
ffffffffc0200d6a:	000b5697          	auipc	a3,0xb5
ffffffffc0200d6e:	93668693          	addi	a3,a3,-1738 # ffffffffc02b56a0 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200d72:	6298                	ld	a4,0(a3)
ffffffffc0200d74:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200d78:	e619                	bnez	a2,ffffffffc0200d86 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200d7a:	0b072783          	lw	a5,176(a4)
ffffffffc0200d7e:	8b85                	andi	a5,a5,1
ffffffffc0200d80:	e79d                	bnez	a5,ffffffffc0200dae <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200d82:	6f1c                	ld	a5,24(a4)
ffffffffc0200d84:	e38d                	bnez	a5,ffffffffc0200da6 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200d86:	60e2                	ld	ra,24(sp)
ffffffffc0200d88:	6105                	addi	sp,sp,32
ffffffffc0200d8a:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200d8c:	dc5ff0ef          	jal	ffffffffc0200b50 <interrupt_handler>
ffffffffc0200d90:	6802                	ld	a6,0(sp)
ffffffffc0200d92:	6622                	ld	a2,8(sp)
ffffffffc0200d94:	000b5697          	auipc	a3,0xb5
ffffffffc0200d98:	90c68693          	addi	a3,a3,-1780 # ffffffffc02b56a0 <current>
ffffffffc0200d9c:	bfd9                	j	ffffffffc0200d72 <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d9e:	0005c363          	bltz	a1,ffffffffc0200da4 <trap+0x6a>
        exception_handler(tf);
ffffffffc0200da2:	bd95                	j	ffffffffc0200c16 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200da4:	b375                	j	ffffffffc0200b50 <interrupt_handler>
}
ffffffffc0200da6:	60e2                	ld	ra,24(sp)
ffffffffc0200da8:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200daa:	48c0406f          	j	ffffffffc0205236 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200dae:	555d                	li	a0,-9
ffffffffc0200db0:	4f0030ef          	jal	ffffffffc02042a0 <do_exit>
            if (current->need_resched)
ffffffffc0200db4:	000b5717          	auipc	a4,0xb5
ffffffffc0200db8:	8ec73703          	ld	a4,-1812(a4) # ffffffffc02b56a0 <current>
ffffffffc0200dbc:	b7d9                	j	ffffffffc0200d82 <trap+0x48>
	...

ffffffffc0200dc0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200dc0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200dc4:	00011463          	bnez	sp,ffffffffc0200dcc <__alltraps+0xc>
ffffffffc0200dc8:	14002173          	csrr	sp,sscratch
ffffffffc0200dcc:	712d                	addi	sp,sp,-288
ffffffffc0200dce:	e002                	sd	zero,0(sp)
ffffffffc0200dd0:	e406                	sd	ra,8(sp)
ffffffffc0200dd2:	ec0e                	sd	gp,24(sp)
ffffffffc0200dd4:	f012                	sd	tp,32(sp)
ffffffffc0200dd6:	f416                	sd	t0,40(sp)
ffffffffc0200dd8:	f81a                	sd	t1,48(sp)
ffffffffc0200dda:	fc1e                	sd	t2,56(sp)
ffffffffc0200ddc:	e0a2                	sd	s0,64(sp)
ffffffffc0200dde:	e4a6                	sd	s1,72(sp)
ffffffffc0200de0:	e8aa                	sd	a0,80(sp)
ffffffffc0200de2:	ecae                	sd	a1,88(sp)
ffffffffc0200de4:	f0b2                	sd	a2,96(sp)
ffffffffc0200de6:	f4b6                	sd	a3,104(sp)
ffffffffc0200de8:	f8ba                	sd	a4,112(sp)
ffffffffc0200dea:	fcbe                	sd	a5,120(sp)
ffffffffc0200dec:	e142                	sd	a6,128(sp)
ffffffffc0200dee:	e546                	sd	a7,136(sp)
ffffffffc0200df0:	e94a                	sd	s2,144(sp)
ffffffffc0200df2:	ed4e                	sd	s3,152(sp)
ffffffffc0200df4:	f152                	sd	s4,160(sp)
ffffffffc0200df6:	f556                	sd	s5,168(sp)
ffffffffc0200df8:	f95a                	sd	s6,176(sp)
ffffffffc0200dfa:	fd5e                	sd	s7,184(sp)
ffffffffc0200dfc:	e1e2                	sd	s8,192(sp)
ffffffffc0200dfe:	e5e6                	sd	s9,200(sp)
ffffffffc0200e00:	e9ea                	sd	s10,208(sp)
ffffffffc0200e02:	edee                	sd	s11,216(sp)
ffffffffc0200e04:	f1f2                	sd	t3,224(sp)
ffffffffc0200e06:	f5f6                	sd	t4,232(sp)
ffffffffc0200e08:	f9fa                	sd	t5,240(sp)
ffffffffc0200e0a:	fdfe                	sd	t6,248(sp)
ffffffffc0200e0c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e10:	100024f3          	csrr	s1,sstatus
ffffffffc0200e14:	14102973          	csrr	s2,sepc
ffffffffc0200e18:	143029f3          	csrr	s3,stval
ffffffffc0200e1c:	14202a73          	csrr	s4,scause
ffffffffc0200e20:	e822                	sd	s0,16(sp)
ffffffffc0200e22:	e226                	sd	s1,256(sp)
ffffffffc0200e24:	e64a                	sd	s2,264(sp)
ffffffffc0200e26:	ea4e                	sd	s3,272(sp)
ffffffffc0200e28:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e2a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e2c:	f0fff0ef          	jal	ffffffffc0200d3a <trap>

ffffffffc0200e30 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e30:	6492                	ld	s1,256(sp)
ffffffffc0200e32:	6932                	ld	s2,264(sp)
ffffffffc0200e34:	1004f413          	andi	s0,s1,256
ffffffffc0200e38:	e401                	bnez	s0,ffffffffc0200e40 <__trapret+0x10>
ffffffffc0200e3a:	1200                	addi	s0,sp,288
ffffffffc0200e3c:	14041073          	csrw	sscratch,s0
ffffffffc0200e40:	10049073          	csrw	sstatus,s1
ffffffffc0200e44:	14191073          	csrw	sepc,s2
ffffffffc0200e48:	60a2                	ld	ra,8(sp)
ffffffffc0200e4a:	61e2                	ld	gp,24(sp)
ffffffffc0200e4c:	7202                	ld	tp,32(sp)
ffffffffc0200e4e:	72a2                	ld	t0,40(sp)
ffffffffc0200e50:	7342                	ld	t1,48(sp)
ffffffffc0200e52:	73e2                	ld	t2,56(sp)
ffffffffc0200e54:	6406                	ld	s0,64(sp)
ffffffffc0200e56:	64a6                	ld	s1,72(sp)
ffffffffc0200e58:	6546                	ld	a0,80(sp)
ffffffffc0200e5a:	65e6                	ld	a1,88(sp)
ffffffffc0200e5c:	7606                	ld	a2,96(sp)
ffffffffc0200e5e:	76a6                	ld	a3,104(sp)
ffffffffc0200e60:	7746                	ld	a4,112(sp)
ffffffffc0200e62:	77e6                	ld	a5,120(sp)
ffffffffc0200e64:	680a                	ld	a6,128(sp)
ffffffffc0200e66:	68aa                	ld	a7,136(sp)
ffffffffc0200e68:	694a                	ld	s2,144(sp)
ffffffffc0200e6a:	69ea                	ld	s3,152(sp)
ffffffffc0200e6c:	7a0a                	ld	s4,160(sp)
ffffffffc0200e6e:	7aaa                	ld	s5,168(sp)
ffffffffc0200e70:	7b4a                	ld	s6,176(sp)
ffffffffc0200e72:	7bea                	ld	s7,184(sp)
ffffffffc0200e74:	6c0e                	ld	s8,192(sp)
ffffffffc0200e76:	6cae                	ld	s9,200(sp)
ffffffffc0200e78:	6d4e                	ld	s10,208(sp)
ffffffffc0200e7a:	6dee                	ld	s11,216(sp)
ffffffffc0200e7c:	7e0e                	ld	t3,224(sp)
ffffffffc0200e7e:	7eae                	ld	t4,232(sp)
ffffffffc0200e80:	7f4e                	ld	t5,240(sp)
ffffffffc0200e82:	7fee                	ld	t6,248(sp)
ffffffffc0200e84:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200e86:	10200073          	sret

ffffffffc0200e8a <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200e8a:	812a                	mv	sp,a0
ffffffffc0200e8c:	b755                	j	ffffffffc0200e30 <__trapret>

ffffffffc0200e8e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e8e:	000b0797          	auipc	a5,0xb0
ffffffffc0200e92:	75a78793          	addi	a5,a5,1882 # ffffffffc02b15e8 <free_area>
ffffffffc0200e96:	e79c                	sd	a5,8(a5)
ffffffffc0200e98:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e9a:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e9e:	8082                	ret

ffffffffc0200ea0 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200ea0:	000b0517          	auipc	a0,0xb0
ffffffffc0200ea4:	75856503          	lwu	a0,1880(a0) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc0200ea8:	8082                	ret

ffffffffc0200eaa <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200eaa:	711d                	addi	sp,sp,-96
ffffffffc0200eac:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200eae:	000b0917          	auipc	s2,0xb0
ffffffffc0200eb2:	73a90913          	addi	s2,s2,1850 # ffffffffc02b15e8 <free_area>
ffffffffc0200eb6:	00893783          	ld	a5,8(s2)
ffffffffc0200eba:	ec86                	sd	ra,88(sp)
ffffffffc0200ebc:	e8a2                	sd	s0,80(sp)
ffffffffc0200ebe:	e4a6                	sd	s1,72(sp)
ffffffffc0200ec0:	fc4e                	sd	s3,56(sp)
ffffffffc0200ec2:	f852                	sd	s4,48(sp)
ffffffffc0200ec4:	f456                	sd	s5,40(sp)
ffffffffc0200ec6:	f05a                	sd	s6,32(sp)
ffffffffc0200ec8:	ec5e                	sd	s7,24(sp)
ffffffffc0200eca:	e862                	sd	s8,16(sp)
ffffffffc0200ecc:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ece:	2f278363          	beq	a5,s2,ffffffffc02011b4 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200ed2:	4401                	li	s0,0
ffffffffc0200ed4:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ed6:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200eda:	8b09                	andi	a4,a4,2
ffffffffc0200edc:	2e070063          	beqz	a4,ffffffffc02011bc <default_check+0x312>
        count++, total += p->property;
ffffffffc0200ee0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ee4:	679c                	ld	a5,8(a5)
ffffffffc0200ee6:	2485                	addiw	s1,s1,1
ffffffffc0200ee8:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200eea:	ff2796e3          	bne	a5,s2,ffffffffc0200ed6 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200eee:	89a2                	mv	s3,s0
ffffffffc0200ef0:	741000ef          	jal	ffffffffc0201e30 <nr_free_pages>
ffffffffc0200ef4:	73351463          	bne	a0,s3,ffffffffc020161c <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ef8:	4505                	li	a0,1
ffffffffc0200efa:	6c5000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0200efe:	8a2a                	mv	s4,a0
ffffffffc0200f00:	44050e63          	beqz	a0,ffffffffc020135c <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f04:	4505                	li	a0,1
ffffffffc0200f06:	6b9000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0200f0a:	89aa                	mv	s3,a0
ffffffffc0200f0c:	72050863          	beqz	a0,ffffffffc020163c <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f10:	4505                	li	a0,1
ffffffffc0200f12:	6ad000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0200f16:	8aaa                	mv	s5,a0
ffffffffc0200f18:	4c050263          	beqz	a0,ffffffffc02013dc <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f1c:	40a987b3          	sub	a5,s3,a0
ffffffffc0200f20:	40aa0733          	sub	a4,s4,a0
ffffffffc0200f24:	0017b793          	seqz	a5,a5
ffffffffc0200f28:	00173713          	seqz	a4,a4
ffffffffc0200f2c:	8fd9                	or	a5,a5,a4
ffffffffc0200f2e:	30079763          	bnez	a5,ffffffffc020123c <default_check+0x392>
ffffffffc0200f32:	313a0563          	beq	s4,s3,ffffffffc020123c <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f36:	000a2783          	lw	a5,0(s4)
ffffffffc0200f3a:	2a079163          	bnez	a5,ffffffffc02011dc <default_check+0x332>
ffffffffc0200f3e:	0009a783          	lw	a5,0(s3)
ffffffffc0200f42:	28079d63          	bnez	a5,ffffffffc02011dc <default_check+0x332>
ffffffffc0200f46:	411c                	lw	a5,0(a0)
ffffffffc0200f48:	28079a63          	bnez	a5,ffffffffc02011dc <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200f4c:	000b4797          	auipc	a5,0xb4
ffffffffc0200f50:	7447b783          	ld	a5,1860(a5) # ffffffffc02b5690 <pages>
ffffffffc0200f54:	00007617          	auipc	a2,0x7
ffffffffc0200f58:	1c463603          	ld	a2,452(a2) # ffffffffc0208118 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f5c:	000b4697          	auipc	a3,0xb4
ffffffffc0200f60:	72c6b683          	ld	a3,1836(a3) # ffffffffc02b5688 <npage>
ffffffffc0200f64:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f68:	8719                	srai	a4,a4,0x6
ffffffffc0200f6a:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f6c:	0732                	slli	a4,a4,0xc
ffffffffc0200f6e:	06b2                	slli	a3,a3,0xc
ffffffffc0200f70:	2ad77663          	bgeu	a4,a3,ffffffffc020121c <default_check+0x372>
    return page - pages + nbase;
ffffffffc0200f74:	40f98733          	sub	a4,s3,a5
ffffffffc0200f78:	8719                	srai	a4,a4,0x6
ffffffffc0200f7a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f7c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f7e:	4cd77f63          	bgeu	a4,a3,ffffffffc020145c <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc0200f82:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f86:	8799                	srai	a5,a5,0x6
ffffffffc0200f88:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f8a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f8c:	32d7f863          	bgeu	a5,a3,ffffffffc02012bc <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc0200f90:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f92:	00093c03          	ld	s8,0(s2)
ffffffffc0200f96:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f9a:	000b0b17          	auipc	s6,0xb0
ffffffffc0200f9e:	65eb2b03          	lw	s6,1630(s6) # ffffffffc02b15f8 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200fa2:	01293023          	sd	s2,0(s2)
ffffffffc0200fa6:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200faa:	000b0797          	auipc	a5,0xb0
ffffffffc0200fae:	6407a723          	sw	zero,1614(a5) # ffffffffc02b15f8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200fb2:	60d000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0200fb6:	2e051363          	bnez	a0,ffffffffc020129c <default_check+0x3f2>
    free_page(p0);
ffffffffc0200fba:	8552                	mv	a0,s4
ffffffffc0200fbc:	4585                	li	a1,1
ffffffffc0200fbe:	63b000ef          	jal	ffffffffc0201df8 <free_pages>
    free_page(p1);
ffffffffc0200fc2:	854e                	mv	a0,s3
ffffffffc0200fc4:	4585                	li	a1,1
ffffffffc0200fc6:	633000ef          	jal	ffffffffc0201df8 <free_pages>
    free_page(p2);
ffffffffc0200fca:	8556                	mv	a0,s5
ffffffffc0200fcc:	4585                	li	a1,1
ffffffffc0200fce:	62b000ef          	jal	ffffffffc0201df8 <free_pages>
    assert(nr_free == 3);
ffffffffc0200fd2:	000b0717          	auipc	a4,0xb0
ffffffffc0200fd6:	62672703          	lw	a4,1574(a4) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc0200fda:	478d                	li	a5,3
ffffffffc0200fdc:	2af71063          	bne	a4,a5,ffffffffc020127c <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fe0:	4505                	li	a0,1
ffffffffc0200fe2:	5dd000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0200fe6:	89aa                	mv	s3,a0
ffffffffc0200fe8:	26050a63          	beqz	a0,ffffffffc020125c <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fec:	4505                	li	a0,1
ffffffffc0200fee:	5d1000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0200ff2:	8aaa                	mv	s5,a0
ffffffffc0200ff4:	3c050463          	beqz	a0,ffffffffc02013bc <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ff8:	4505                	li	a0,1
ffffffffc0200ffa:	5c5000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0200ffe:	8a2a                	mv	s4,a0
ffffffffc0201000:	38050e63          	beqz	a0,ffffffffc020139c <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc0201004:	4505                	li	a0,1
ffffffffc0201006:	5b9000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc020100a:	36051963          	bnez	a0,ffffffffc020137c <default_check+0x4d2>
    free_page(p0);
ffffffffc020100e:	4585                	li	a1,1
ffffffffc0201010:	854e                	mv	a0,s3
ffffffffc0201012:	5e7000ef          	jal	ffffffffc0201df8 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201016:	00893783          	ld	a5,8(s2)
ffffffffc020101a:	1f278163          	beq	a5,s2,ffffffffc02011fc <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc020101e:	4505                	li	a0,1
ffffffffc0201020:	59f000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0201024:	8caa                	mv	s9,a0
ffffffffc0201026:	30a99b63          	bne	s3,a0,ffffffffc020133c <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc020102a:	4505                	li	a0,1
ffffffffc020102c:	593000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0201030:	2e051663          	bnez	a0,ffffffffc020131c <default_check+0x472>
    assert(nr_free == 0);
ffffffffc0201034:	000b0797          	auipc	a5,0xb0
ffffffffc0201038:	5c47a783          	lw	a5,1476(a5) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc020103c:	2c079063          	bnez	a5,ffffffffc02012fc <default_check+0x452>
    free_page(p);
ffffffffc0201040:	8566                	mv	a0,s9
ffffffffc0201042:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201044:	01893023          	sd	s8,0(s2)
ffffffffc0201048:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc020104c:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0201050:	5a9000ef          	jal	ffffffffc0201df8 <free_pages>
    free_page(p1);
ffffffffc0201054:	8556                	mv	a0,s5
ffffffffc0201056:	4585                	li	a1,1
ffffffffc0201058:	5a1000ef          	jal	ffffffffc0201df8 <free_pages>
    free_page(p2);
ffffffffc020105c:	8552                	mv	a0,s4
ffffffffc020105e:	4585                	li	a1,1
ffffffffc0201060:	599000ef          	jal	ffffffffc0201df8 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201064:	4515                	li	a0,5
ffffffffc0201066:	559000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc020106a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020106c:	26050863          	beqz	a0,ffffffffc02012dc <default_check+0x432>
ffffffffc0201070:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc0201072:	8b89                	andi	a5,a5,2
ffffffffc0201074:	54079463          	bnez	a5,ffffffffc02015bc <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201078:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020107a:	00093b83          	ld	s7,0(s2)
ffffffffc020107e:	00893b03          	ld	s6,8(s2)
ffffffffc0201082:	01293023          	sd	s2,0(s2)
ffffffffc0201086:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc020108a:	535000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc020108e:	50051763          	bnez	a0,ffffffffc020159c <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201092:	08098a13          	addi	s4,s3,128
ffffffffc0201096:	8552                	mv	a0,s4
ffffffffc0201098:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020109a:	000b0c17          	auipc	s8,0xb0
ffffffffc020109e:	55ec2c03          	lw	s8,1374(s8) # ffffffffc02b15f8 <free_area+0x10>
    nr_free = 0;
ffffffffc02010a2:	000b0797          	auipc	a5,0xb0
ffffffffc02010a6:	5407ab23          	sw	zero,1366(a5) # ffffffffc02b15f8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010aa:	54f000ef          	jal	ffffffffc0201df8 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02010ae:	4511                	li	a0,4
ffffffffc02010b0:	50f000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc02010b4:	4c051463          	bnez	a0,ffffffffc020157c <default_check+0x6d2>
ffffffffc02010b8:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02010bc:	8b89                	andi	a5,a5,2
ffffffffc02010be:	48078f63          	beqz	a5,ffffffffc020155c <default_check+0x6b2>
ffffffffc02010c2:	0909a503          	lw	a0,144(s3)
ffffffffc02010c6:	478d                	li	a5,3
ffffffffc02010c8:	48f51a63          	bne	a0,a5,ffffffffc020155c <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010cc:	4f3000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc02010d0:	8aaa                	mv	s5,a0
ffffffffc02010d2:	46050563          	beqz	a0,ffffffffc020153c <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc02010d6:	4505                	li	a0,1
ffffffffc02010d8:	4e7000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc02010dc:	44051063          	bnez	a0,ffffffffc020151c <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc02010e0:	415a1e63          	bne	s4,s5,ffffffffc02014fc <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010e4:	4585                	li	a1,1
ffffffffc02010e6:	854e                	mv	a0,s3
ffffffffc02010e8:	511000ef          	jal	ffffffffc0201df8 <free_pages>
    free_pages(p1, 3);
ffffffffc02010ec:	8552                	mv	a0,s4
ffffffffc02010ee:	458d                	li	a1,3
ffffffffc02010f0:	509000ef          	jal	ffffffffc0201df8 <free_pages>
ffffffffc02010f4:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010f8:	8b89                	andi	a5,a5,2
ffffffffc02010fa:	3e078163          	beqz	a5,ffffffffc02014dc <default_check+0x632>
ffffffffc02010fe:	0109aa83          	lw	s5,16(s3)
ffffffffc0201102:	4785                	li	a5,1
ffffffffc0201104:	3cfa9c63          	bne	s5,a5,ffffffffc02014dc <default_check+0x632>
ffffffffc0201108:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020110c:	8b89                	andi	a5,a5,2
ffffffffc020110e:	3a078763          	beqz	a5,ffffffffc02014bc <default_check+0x612>
ffffffffc0201112:	010a2703          	lw	a4,16(s4)
ffffffffc0201116:	478d                	li	a5,3
ffffffffc0201118:	3af71263          	bne	a4,a5,ffffffffc02014bc <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020111c:	8556                	mv	a0,s5
ffffffffc020111e:	4a1000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0201122:	36a99d63          	bne	s3,a0,ffffffffc020149c <default_check+0x5f2>
    free_page(p0);
ffffffffc0201126:	85d6                	mv	a1,s5
ffffffffc0201128:	4d1000ef          	jal	ffffffffc0201df8 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020112c:	4509                	li	a0,2
ffffffffc020112e:	491000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0201132:	34aa1563          	bne	s4,a0,ffffffffc020147c <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc0201136:	4589                	li	a1,2
ffffffffc0201138:	4c1000ef          	jal	ffffffffc0201df8 <free_pages>
    free_page(p2);
ffffffffc020113c:	04098513          	addi	a0,s3,64
ffffffffc0201140:	85d6                	mv	a1,s5
ffffffffc0201142:	4b7000ef          	jal	ffffffffc0201df8 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201146:	4515                	li	a0,5
ffffffffc0201148:	477000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc020114c:	89aa                	mv	s3,a0
ffffffffc020114e:	48050763          	beqz	a0,ffffffffc02015dc <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc0201152:	8556                	mv	a0,s5
ffffffffc0201154:	46b000ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0201158:	2e051263          	bnez	a0,ffffffffc020143c <default_check+0x592>

    assert(nr_free == 0);
ffffffffc020115c:	000b0797          	auipc	a5,0xb0
ffffffffc0201160:	49c7a783          	lw	a5,1180(a5) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc0201164:	2a079c63          	bnez	a5,ffffffffc020141c <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201168:	854e                	mv	a0,s3
ffffffffc020116a:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc020116c:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201170:	01793023          	sd	s7,0(s2)
ffffffffc0201174:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201178:	481000ef          	jal	ffffffffc0201df8 <free_pages>
    return listelm->next;
ffffffffc020117c:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201180:	01278963          	beq	a5,s2,ffffffffc0201192 <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201184:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201188:	679c                	ld	a5,8(a5)
ffffffffc020118a:	34fd                	addiw	s1,s1,-1
ffffffffc020118c:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020118e:	ff279be3          	bne	a5,s2,ffffffffc0201184 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc0201192:	26049563          	bnez	s1,ffffffffc02013fc <default_check+0x552>
    assert(total == 0);
ffffffffc0201196:	46041363          	bnez	s0,ffffffffc02015fc <default_check+0x752>
}
ffffffffc020119a:	60e6                	ld	ra,88(sp)
ffffffffc020119c:	6446                	ld	s0,80(sp)
ffffffffc020119e:	64a6                	ld	s1,72(sp)
ffffffffc02011a0:	6906                	ld	s2,64(sp)
ffffffffc02011a2:	79e2                	ld	s3,56(sp)
ffffffffc02011a4:	7a42                	ld	s4,48(sp)
ffffffffc02011a6:	7aa2                	ld	s5,40(sp)
ffffffffc02011a8:	7b02                	ld	s6,32(sp)
ffffffffc02011aa:	6be2                	ld	s7,24(sp)
ffffffffc02011ac:	6c42                	ld	s8,16(sp)
ffffffffc02011ae:	6ca2                	ld	s9,8(sp)
ffffffffc02011b0:	6125                	addi	sp,sp,96
ffffffffc02011b2:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02011b4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02011b6:	4401                	li	s0,0
ffffffffc02011b8:	4481                	li	s1,0
ffffffffc02011ba:	bb1d                	j	ffffffffc0200ef0 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc02011bc:	00005697          	auipc	a3,0x5
ffffffffc02011c0:	0bc68693          	addi	a3,a3,188 # ffffffffc0206278 <etext+0x9d0>
ffffffffc02011c4:	00005617          	auipc	a2,0x5
ffffffffc02011c8:	0c460613          	addi	a2,a2,196 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02011cc:	11000593          	li	a1,272
ffffffffc02011d0:	00005517          	auipc	a0,0x5
ffffffffc02011d4:	0d050513          	addi	a0,a0,208 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02011d8:	a72ff0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011dc:	00005697          	auipc	a3,0x5
ffffffffc02011e0:	18468693          	addi	a3,a3,388 # ffffffffc0206360 <etext+0xab8>
ffffffffc02011e4:	00005617          	auipc	a2,0x5
ffffffffc02011e8:	0a460613          	addi	a2,a2,164 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02011ec:	0dc00593          	li	a1,220
ffffffffc02011f0:	00005517          	auipc	a0,0x5
ffffffffc02011f4:	0b050513          	addi	a0,a0,176 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02011f8:	a52ff0ef          	jal	ffffffffc020044a <__panic>
    assert(!list_empty(&free_list));
ffffffffc02011fc:	00005697          	auipc	a3,0x5
ffffffffc0201200:	22c68693          	addi	a3,a3,556 # ffffffffc0206428 <etext+0xb80>
ffffffffc0201204:	00005617          	auipc	a2,0x5
ffffffffc0201208:	08460613          	addi	a2,a2,132 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020120c:	0f700593          	li	a1,247
ffffffffc0201210:	00005517          	auipc	a0,0x5
ffffffffc0201214:	09050513          	addi	a0,a0,144 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201218:	a32ff0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020121c:	00005697          	auipc	a3,0x5
ffffffffc0201220:	18468693          	addi	a3,a3,388 # ffffffffc02063a0 <etext+0xaf8>
ffffffffc0201224:	00005617          	auipc	a2,0x5
ffffffffc0201228:	06460613          	addi	a2,a2,100 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020122c:	0de00593          	li	a1,222
ffffffffc0201230:	00005517          	auipc	a0,0x5
ffffffffc0201234:	07050513          	addi	a0,a0,112 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201238:	a12ff0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020123c:	00005697          	auipc	a3,0x5
ffffffffc0201240:	0fc68693          	addi	a3,a3,252 # ffffffffc0206338 <etext+0xa90>
ffffffffc0201244:	00005617          	auipc	a2,0x5
ffffffffc0201248:	04460613          	addi	a2,a2,68 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020124c:	0db00593          	li	a1,219
ffffffffc0201250:	00005517          	auipc	a0,0x5
ffffffffc0201254:	05050513          	addi	a0,a0,80 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201258:	9f2ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020125c:	00005697          	auipc	a3,0x5
ffffffffc0201260:	07c68693          	addi	a3,a3,124 # ffffffffc02062d8 <etext+0xa30>
ffffffffc0201264:	00005617          	auipc	a2,0x5
ffffffffc0201268:	02460613          	addi	a2,a2,36 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020126c:	0f000593          	li	a1,240
ffffffffc0201270:	00005517          	auipc	a0,0x5
ffffffffc0201274:	03050513          	addi	a0,a0,48 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201278:	9d2ff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 3);
ffffffffc020127c:	00005697          	auipc	a3,0x5
ffffffffc0201280:	19c68693          	addi	a3,a3,412 # ffffffffc0206418 <etext+0xb70>
ffffffffc0201284:	00005617          	auipc	a2,0x5
ffffffffc0201288:	00460613          	addi	a2,a2,4 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020128c:	0ee00593          	li	a1,238
ffffffffc0201290:	00005517          	auipc	a0,0x5
ffffffffc0201294:	01050513          	addi	a0,a0,16 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201298:	9b2ff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc020129c:	00005697          	auipc	a3,0x5
ffffffffc02012a0:	16468693          	addi	a3,a3,356 # ffffffffc0206400 <etext+0xb58>
ffffffffc02012a4:	00005617          	auipc	a2,0x5
ffffffffc02012a8:	fe460613          	addi	a2,a2,-28 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02012ac:	0e900593          	li	a1,233
ffffffffc02012b0:	00005517          	auipc	a0,0x5
ffffffffc02012b4:	ff050513          	addi	a0,a0,-16 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02012b8:	992ff0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012bc:	00005697          	auipc	a3,0x5
ffffffffc02012c0:	12468693          	addi	a3,a3,292 # ffffffffc02063e0 <etext+0xb38>
ffffffffc02012c4:	00005617          	auipc	a2,0x5
ffffffffc02012c8:	fc460613          	addi	a2,a2,-60 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02012cc:	0e000593          	li	a1,224
ffffffffc02012d0:	00005517          	auipc	a0,0x5
ffffffffc02012d4:	fd050513          	addi	a0,a0,-48 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02012d8:	972ff0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 != NULL);
ffffffffc02012dc:	00005697          	auipc	a3,0x5
ffffffffc02012e0:	19468693          	addi	a3,a3,404 # ffffffffc0206470 <etext+0xbc8>
ffffffffc02012e4:	00005617          	auipc	a2,0x5
ffffffffc02012e8:	fa460613          	addi	a2,a2,-92 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02012ec:	11800593          	li	a1,280
ffffffffc02012f0:	00005517          	auipc	a0,0x5
ffffffffc02012f4:	fb050513          	addi	a0,a0,-80 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02012f8:	952ff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 0);
ffffffffc02012fc:	00005697          	auipc	a3,0x5
ffffffffc0201300:	16468693          	addi	a3,a3,356 # ffffffffc0206460 <etext+0xbb8>
ffffffffc0201304:	00005617          	auipc	a2,0x5
ffffffffc0201308:	f8460613          	addi	a2,a2,-124 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020130c:	0fd00593          	li	a1,253
ffffffffc0201310:	00005517          	auipc	a0,0x5
ffffffffc0201314:	f9050513          	addi	a0,a0,-112 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201318:	932ff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc020131c:	00005697          	auipc	a3,0x5
ffffffffc0201320:	0e468693          	addi	a3,a3,228 # ffffffffc0206400 <etext+0xb58>
ffffffffc0201324:	00005617          	auipc	a2,0x5
ffffffffc0201328:	f6460613          	addi	a2,a2,-156 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020132c:	0fb00593          	li	a1,251
ffffffffc0201330:	00005517          	auipc	a0,0x5
ffffffffc0201334:	f7050513          	addi	a0,a0,-144 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201338:	912ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020133c:	00005697          	auipc	a3,0x5
ffffffffc0201340:	10468693          	addi	a3,a3,260 # ffffffffc0206440 <etext+0xb98>
ffffffffc0201344:	00005617          	auipc	a2,0x5
ffffffffc0201348:	f4460613          	addi	a2,a2,-188 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020134c:	0fa00593          	li	a1,250
ffffffffc0201350:	00005517          	auipc	a0,0x5
ffffffffc0201354:	f5050513          	addi	a0,a0,-176 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201358:	8f2ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020135c:	00005697          	auipc	a3,0x5
ffffffffc0201360:	f7c68693          	addi	a3,a3,-132 # ffffffffc02062d8 <etext+0xa30>
ffffffffc0201364:	00005617          	auipc	a2,0x5
ffffffffc0201368:	f2460613          	addi	a2,a2,-220 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020136c:	0d700593          	li	a1,215
ffffffffc0201370:	00005517          	auipc	a0,0x5
ffffffffc0201374:	f3050513          	addi	a0,a0,-208 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201378:	8d2ff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc020137c:	00005697          	auipc	a3,0x5
ffffffffc0201380:	08468693          	addi	a3,a3,132 # ffffffffc0206400 <etext+0xb58>
ffffffffc0201384:	00005617          	auipc	a2,0x5
ffffffffc0201388:	f0460613          	addi	a2,a2,-252 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020138c:	0f400593          	li	a1,244
ffffffffc0201390:	00005517          	auipc	a0,0x5
ffffffffc0201394:	f1050513          	addi	a0,a0,-240 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201398:	8b2ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020139c:	00005697          	auipc	a3,0x5
ffffffffc02013a0:	f7c68693          	addi	a3,a3,-132 # ffffffffc0206318 <etext+0xa70>
ffffffffc02013a4:	00005617          	auipc	a2,0x5
ffffffffc02013a8:	ee460613          	addi	a2,a2,-284 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02013ac:	0f200593          	li	a1,242
ffffffffc02013b0:	00005517          	auipc	a0,0x5
ffffffffc02013b4:	ef050513          	addi	a0,a0,-272 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02013b8:	892ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013bc:	00005697          	auipc	a3,0x5
ffffffffc02013c0:	f3c68693          	addi	a3,a3,-196 # ffffffffc02062f8 <etext+0xa50>
ffffffffc02013c4:	00005617          	auipc	a2,0x5
ffffffffc02013c8:	ec460613          	addi	a2,a2,-316 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02013cc:	0f100593          	li	a1,241
ffffffffc02013d0:	00005517          	auipc	a0,0x5
ffffffffc02013d4:	ed050513          	addi	a0,a0,-304 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02013d8:	872ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013dc:	00005697          	auipc	a3,0x5
ffffffffc02013e0:	f3c68693          	addi	a3,a3,-196 # ffffffffc0206318 <etext+0xa70>
ffffffffc02013e4:	00005617          	auipc	a2,0x5
ffffffffc02013e8:	ea460613          	addi	a2,a2,-348 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02013ec:	0d900593          	li	a1,217
ffffffffc02013f0:	00005517          	auipc	a0,0x5
ffffffffc02013f4:	eb050513          	addi	a0,a0,-336 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02013f8:	852ff0ef          	jal	ffffffffc020044a <__panic>
    assert(count == 0);
ffffffffc02013fc:	00005697          	auipc	a3,0x5
ffffffffc0201400:	1c468693          	addi	a3,a3,452 # ffffffffc02065c0 <etext+0xd18>
ffffffffc0201404:	00005617          	auipc	a2,0x5
ffffffffc0201408:	e8460613          	addi	a2,a2,-380 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020140c:	14600593          	li	a1,326
ffffffffc0201410:	00005517          	auipc	a0,0x5
ffffffffc0201414:	e9050513          	addi	a0,a0,-368 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201418:	832ff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 0);
ffffffffc020141c:	00005697          	auipc	a3,0x5
ffffffffc0201420:	04468693          	addi	a3,a3,68 # ffffffffc0206460 <etext+0xbb8>
ffffffffc0201424:	00005617          	auipc	a2,0x5
ffffffffc0201428:	e6460613          	addi	a2,a2,-412 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020142c:	13a00593          	li	a1,314
ffffffffc0201430:	00005517          	auipc	a0,0x5
ffffffffc0201434:	e7050513          	addi	a0,a0,-400 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201438:	812ff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc020143c:	00005697          	auipc	a3,0x5
ffffffffc0201440:	fc468693          	addi	a3,a3,-60 # ffffffffc0206400 <etext+0xb58>
ffffffffc0201444:	00005617          	auipc	a2,0x5
ffffffffc0201448:	e4460613          	addi	a2,a2,-444 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020144c:	13800593          	li	a1,312
ffffffffc0201450:	00005517          	auipc	a0,0x5
ffffffffc0201454:	e5050513          	addi	a0,a0,-432 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201458:	ff3fe0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020145c:	00005697          	auipc	a3,0x5
ffffffffc0201460:	f6468693          	addi	a3,a3,-156 # ffffffffc02063c0 <etext+0xb18>
ffffffffc0201464:	00005617          	auipc	a2,0x5
ffffffffc0201468:	e2460613          	addi	a2,a2,-476 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020146c:	0df00593          	li	a1,223
ffffffffc0201470:	00005517          	auipc	a0,0x5
ffffffffc0201474:	e3050513          	addi	a0,a0,-464 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201478:	fd3fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020147c:	00005697          	auipc	a3,0x5
ffffffffc0201480:	10468693          	addi	a3,a3,260 # ffffffffc0206580 <etext+0xcd8>
ffffffffc0201484:	00005617          	auipc	a2,0x5
ffffffffc0201488:	e0460613          	addi	a2,a2,-508 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020148c:	13200593          	li	a1,306
ffffffffc0201490:	00005517          	auipc	a0,0x5
ffffffffc0201494:	e1050513          	addi	a0,a0,-496 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201498:	fb3fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020149c:	00005697          	auipc	a3,0x5
ffffffffc02014a0:	0c468693          	addi	a3,a3,196 # ffffffffc0206560 <etext+0xcb8>
ffffffffc02014a4:	00005617          	auipc	a2,0x5
ffffffffc02014a8:	de460613          	addi	a2,a2,-540 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02014ac:	13000593          	li	a1,304
ffffffffc02014b0:	00005517          	auipc	a0,0x5
ffffffffc02014b4:	df050513          	addi	a0,a0,-528 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02014b8:	f93fe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014bc:	00005697          	auipc	a3,0x5
ffffffffc02014c0:	07c68693          	addi	a3,a3,124 # ffffffffc0206538 <etext+0xc90>
ffffffffc02014c4:	00005617          	auipc	a2,0x5
ffffffffc02014c8:	dc460613          	addi	a2,a2,-572 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02014cc:	12e00593          	li	a1,302
ffffffffc02014d0:	00005517          	auipc	a0,0x5
ffffffffc02014d4:	dd050513          	addi	a0,a0,-560 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02014d8:	f73fe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014dc:	00005697          	auipc	a3,0x5
ffffffffc02014e0:	03468693          	addi	a3,a3,52 # ffffffffc0206510 <etext+0xc68>
ffffffffc02014e4:	00005617          	auipc	a2,0x5
ffffffffc02014e8:	da460613          	addi	a2,a2,-604 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02014ec:	12d00593          	li	a1,301
ffffffffc02014f0:	00005517          	auipc	a0,0x5
ffffffffc02014f4:	db050513          	addi	a0,a0,-592 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02014f8:	f53fe0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014fc:	00005697          	auipc	a3,0x5
ffffffffc0201500:	00468693          	addi	a3,a3,4 # ffffffffc0206500 <etext+0xc58>
ffffffffc0201504:	00005617          	auipc	a2,0x5
ffffffffc0201508:	d8460613          	addi	a2,a2,-636 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020150c:	12800593          	li	a1,296
ffffffffc0201510:	00005517          	auipc	a0,0x5
ffffffffc0201514:	d9050513          	addi	a0,a0,-624 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201518:	f33fe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc020151c:	00005697          	auipc	a3,0x5
ffffffffc0201520:	ee468693          	addi	a3,a3,-284 # ffffffffc0206400 <etext+0xb58>
ffffffffc0201524:	00005617          	auipc	a2,0x5
ffffffffc0201528:	d6460613          	addi	a2,a2,-668 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020152c:	12700593          	li	a1,295
ffffffffc0201530:	00005517          	auipc	a0,0x5
ffffffffc0201534:	d7050513          	addi	a0,a0,-656 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201538:	f13fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020153c:	00005697          	auipc	a3,0x5
ffffffffc0201540:	fa468693          	addi	a3,a3,-92 # ffffffffc02064e0 <etext+0xc38>
ffffffffc0201544:	00005617          	auipc	a2,0x5
ffffffffc0201548:	d4460613          	addi	a2,a2,-700 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020154c:	12600593          	li	a1,294
ffffffffc0201550:	00005517          	auipc	a0,0x5
ffffffffc0201554:	d5050513          	addi	a0,a0,-688 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201558:	ef3fe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020155c:	00005697          	auipc	a3,0x5
ffffffffc0201560:	f5468693          	addi	a3,a3,-172 # ffffffffc02064b0 <etext+0xc08>
ffffffffc0201564:	00005617          	auipc	a2,0x5
ffffffffc0201568:	d2460613          	addi	a2,a2,-732 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020156c:	12500593          	li	a1,293
ffffffffc0201570:	00005517          	auipc	a0,0x5
ffffffffc0201574:	d3050513          	addi	a0,a0,-720 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201578:	ed3fe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020157c:	00005697          	auipc	a3,0x5
ffffffffc0201580:	f1c68693          	addi	a3,a3,-228 # ffffffffc0206498 <etext+0xbf0>
ffffffffc0201584:	00005617          	auipc	a2,0x5
ffffffffc0201588:	d0460613          	addi	a2,a2,-764 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020158c:	12400593          	li	a1,292
ffffffffc0201590:	00005517          	auipc	a0,0x5
ffffffffc0201594:	d1050513          	addi	a0,a0,-752 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201598:	eb3fe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc020159c:	00005697          	auipc	a3,0x5
ffffffffc02015a0:	e6468693          	addi	a3,a3,-412 # ffffffffc0206400 <etext+0xb58>
ffffffffc02015a4:	00005617          	auipc	a2,0x5
ffffffffc02015a8:	ce460613          	addi	a2,a2,-796 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02015ac:	11e00593          	li	a1,286
ffffffffc02015b0:	00005517          	auipc	a0,0x5
ffffffffc02015b4:	cf050513          	addi	a0,a0,-784 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02015b8:	e93fe0ef          	jal	ffffffffc020044a <__panic>
    assert(!PageProperty(p0));
ffffffffc02015bc:	00005697          	auipc	a3,0x5
ffffffffc02015c0:	ec468693          	addi	a3,a3,-316 # ffffffffc0206480 <etext+0xbd8>
ffffffffc02015c4:	00005617          	auipc	a2,0x5
ffffffffc02015c8:	cc460613          	addi	a2,a2,-828 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02015cc:	11900593          	li	a1,281
ffffffffc02015d0:	00005517          	auipc	a0,0x5
ffffffffc02015d4:	cd050513          	addi	a0,a0,-816 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02015d8:	e73fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015dc:	00005697          	auipc	a3,0x5
ffffffffc02015e0:	fc468693          	addi	a3,a3,-60 # ffffffffc02065a0 <etext+0xcf8>
ffffffffc02015e4:	00005617          	auipc	a2,0x5
ffffffffc02015e8:	ca460613          	addi	a2,a2,-860 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02015ec:	13700593          	li	a1,311
ffffffffc02015f0:	00005517          	auipc	a0,0x5
ffffffffc02015f4:	cb050513          	addi	a0,a0,-848 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02015f8:	e53fe0ef          	jal	ffffffffc020044a <__panic>
    assert(total == 0);
ffffffffc02015fc:	00005697          	auipc	a3,0x5
ffffffffc0201600:	fd468693          	addi	a3,a3,-44 # ffffffffc02065d0 <etext+0xd28>
ffffffffc0201604:	00005617          	auipc	a2,0x5
ffffffffc0201608:	c8460613          	addi	a2,a2,-892 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020160c:	14700593          	li	a1,327
ffffffffc0201610:	00005517          	auipc	a0,0x5
ffffffffc0201614:	c9050513          	addi	a0,a0,-880 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201618:	e33fe0ef          	jal	ffffffffc020044a <__panic>
    assert(total == nr_free_pages());
ffffffffc020161c:	00005697          	auipc	a3,0x5
ffffffffc0201620:	c9c68693          	addi	a3,a3,-868 # ffffffffc02062b8 <etext+0xa10>
ffffffffc0201624:	00005617          	auipc	a2,0x5
ffffffffc0201628:	c6460613          	addi	a2,a2,-924 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020162c:	11300593          	li	a1,275
ffffffffc0201630:	00005517          	auipc	a0,0x5
ffffffffc0201634:	c7050513          	addi	a0,a0,-912 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201638:	e13fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020163c:	00005697          	auipc	a3,0x5
ffffffffc0201640:	cbc68693          	addi	a3,a3,-836 # ffffffffc02062f8 <etext+0xa50>
ffffffffc0201644:	00005617          	auipc	a2,0x5
ffffffffc0201648:	c4460613          	addi	a2,a2,-956 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020164c:	0d800593          	li	a1,216
ffffffffc0201650:	00005517          	auipc	a0,0x5
ffffffffc0201654:	c5050513          	addi	a0,a0,-944 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201658:	df3fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc020165c <default_free_pages>:
{
ffffffffc020165c:	1141                	addi	sp,sp,-16
ffffffffc020165e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201660:	14058663          	beqz	a1,ffffffffc02017ac <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc0201664:	00659713          	slli	a4,a1,0x6
ffffffffc0201668:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020166c:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc020166e:	c30d                	beqz	a4,ffffffffc0201690 <default_free_pages+0x34>
ffffffffc0201670:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201672:	8b05                	andi	a4,a4,1
ffffffffc0201674:	10071c63          	bnez	a4,ffffffffc020178c <default_free_pages+0x130>
ffffffffc0201678:	6798                	ld	a4,8(a5)
ffffffffc020167a:	8b09                	andi	a4,a4,2
ffffffffc020167c:	10071863          	bnez	a4,ffffffffc020178c <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201680:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201684:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201688:	04078793          	addi	a5,a5,64
ffffffffc020168c:	fed792e3          	bne	a5,a3,ffffffffc0201670 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201690:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201692:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201696:	4789                	li	a5,2
ffffffffc0201698:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020169c:	000b0717          	auipc	a4,0xb0
ffffffffc02016a0:	f5c72703          	lw	a4,-164(a4) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc02016a4:	000b0697          	auipc	a3,0xb0
ffffffffc02016a8:	f4468693          	addi	a3,a3,-188 # ffffffffc02b15e8 <free_area>
    return list->next == list;
ffffffffc02016ac:	669c                	ld	a5,8(a3)
ffffffffc02016ae:	9f2d                	addw	a4,a4,a1
ffffffffc02016b0:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02016b2:	0ad78163          	beq	a5,a3,ffffffffc0201754 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc02016b6:	fe878713          	addi	a4,a5,-24
ffffffffc02016ba:	4581                	li	a1,0
ffffffffc02016bc:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02016c0:	00e56a63          	bltu	a0,a4,ffffffffc02016d4 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02016c4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02016c6:	04d70c63          	beq	a4,a3,ffffffffc020171e <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc02016ca:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02016cc:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02016d0:	fee57ae3          	bgeu	a0,a4,ffffffffc02016c4 <default_free_pages+0x68>
ffffffffc02016d4:	c199                	beqz	a1,ffffffffc02016da <default_free_pages+0x7e>
ffffffffc02016d6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016da:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016dc:	e390                	sd	a2,0(a5)
ffffffffc02016de:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc02016e0:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02016e2:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc02016e4:	00d70d63          	beq	a4,a3,ffffffffc02016fe <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02016e8:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016ec:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02016f0:	02059813          	slli	a6,a1,0x20
ffffffffc02016f4:	01a85793          	srli	a5,a6,0x1a
ffffffffc02016f8:	97b2                	add	a5,a5,a2
ffffffffc02016fa:	02f50c63          	beq	a0,a5,ffffffffc0201732 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02016fe:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201700:	00d78c63          	beq	a5,a3,ffffffffc0201718 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201704:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201706:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020170a:	02061593          	slli	a1,a2,0x20
ffffffffc020170e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201712:	972a                	add	a4,a4,a0
ffffffffc0201714:	04e68c63          	beq	a3,a4,ffffffffc020176c <default_free_pages+0x110>
}
ffffffffc0201718:	60a2                	ld	ra,8(sp)
ffffffffc020171a:	0141                	addi	sp,sp,16
ffffffffc020171c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020171e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201720:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201722:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201724:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201726:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201728:	02d70f63          	beq	a4,a3,ffffffffc0201766 <default_free_pages+0x10a>
ffffffffc020172c:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020172e:	87ba                	mv	a5,a4
ffffffffc0201730:	bf71                	j	ffffffffc02016cc <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201732:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201734:	5875                	li	a6,-3
ffffffffc0201736:	9fad                	addw	a5,a5,a1
ffffffffc0201738:	fef72c23          	sw	a5,-8(a4)
ffffffffc020173c:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201740:	01853803          	ld	a6,24(a0)
ffffffffc0201744:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201746:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201748:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_matrix_out_size+0xfe4ac8>
    return listelm->next;
ffffffffc020174c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020174e:	0105b023          	sd	a6,0(a1)
ffffffffc0201752:	b77d                	j	ffffffffc0201700 <default_free_pages+0xa4>
}
ffffffffc0201754:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201756:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020175a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020175c:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020175e:	e398                	sd	a4,0(a5)
ffffffffc0201760:	e798                	sd	a4,8(a5)
}
ffffffffc0201762:	0141                	addi	sp,sp,16
ffffffffc0201764:	8082                	ret
ffffffffc0201766:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201768:	873e                	mv	a4,a5
ffffffffc020176a:	bfad                	j	ffffffffc02016e4 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc020176c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201770:	56f5                	li	a3,-3
ffffffffc0201772:	9f31                	addw	a4,a4,a2
ffffffffc0201774:	c918                	sw	a4,16(a0)
ffffffffc0201776:	ff078713          	addi	a4,a5,-16
ffffffffc020177a:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020177e:	6398                	ld	a4,0(a5)
ffffffffc0201780:	679c                	ld	a5,8(a5)
}
ffffffffc0201782:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201784:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201786:	e398                	sd	a4,0(a5)
ffffffffc0201788:	0141                	addi	sp,sp,16
ffffffffc020178a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020178c:	00005697          	auipc	a3,0x5
ffffffffc0201790:	e5c68693          	addi	a3,a3,-420 # ffffffffc02065e8 <etext+0xd40>
ffffffffc0201794:	00005617          	auipc	a2,0x5
ffffffffc0201798:	af460613          	addi	a2,a2,-1292 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020179c:	09400593          	li	a1,148
ffffffffc02017a0:	00005517          	auipc	a0,0x5
ffffffffc02017a4:	b0050513          	addi	a0,a0,-1280 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02017a8:	ca3fe0ef          	jal	ffffffffc020044a <__panic>
    assert(n > 0);
ffffffffc02017ac:	00005697          	auipc	a3,0x5
ffffffffc02017b0:	e3468693          	addi	a3,a3,-460 # ffffffffc02065e0 <etext+0xd38>
ffffffffc02017b4:	00005617          	auipc	a2,0x5
ffffffffc02017b8:	ad460613          	addi	a2,a2,-1324 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02017bc:	09000593          	li	a1,144
ffffffffc02017c0:	00005517          	auipc	a0,0x5
ffffffffc02017c4:	ae050513          	addi	a0,a0,-1312 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc02017c8:	c83fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02017cc <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017cc:	c951                	beqz	a0,ffffffffc0201860 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc02017ce:	000b0597          	auipc	a1,0xb0
ffffffffc02017d2:	e2a5a583          	lw	a1,-470(a1) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc02017d6:	86aa                	mv	a3,a0
ffffffffc02017d8:	02059793          	slli	a5,a1,0x20
ffffffffc02017dc:	9381                	srli	a5,a5,0x20
ffffffffc02017de:	00a7ef63          	bltu	a5,a0,ffffffffc02017fc <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02017e2:	000b0617          	auipc	a2,0xb0
ffffffffc02017e6:	e0660613          	addi	a2,a2,-506 # ffffffffc02b15e8 <free_area>
ffffffffc02017ea:	87b2                	mv	a5,a2
ffffffffc02017ec:	a029                	j	ffffffffc02017f6 <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc02017ee:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02017f2:	00d77763          	bgeu	a4,a3,ffffffffc0201800 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02017f6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02017f8:	fec79be3          	bne	a5,a2,ffffffffc02017ee <default_alloc_pages+0x22>
        return NULL;
ffffffffc02017fc:	4501                	li	a0,0
}
ffffffffc02017fe:	8082                	ret
        if (page->property > n)
ffffffffc0201800:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc0201804:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201808:	6798                	ld	a4,8(a5)
ffffffffc020180a:	02089313          	slli	t1,a7,0x20
ffffffffc020180e:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc0201812:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201816:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc020181a:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc020181e:	0266fa63          	bgeu	a3,t1,ffffffffc0201852 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc0201822:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc0201826:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc020182a:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020182c:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201830:	00870313          	addi	t1,a4,8
ffffffffc0201834:	4889                	li	a7,2
ffffffffc0201836:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020183a:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020183e:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201842:	0068b023          	sd	t1,0(a7)
ffffffffc0201846:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc020184a:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc020184e:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc0201852:	9d95                	subw	a1,a1,a3
ffffffffc0201854:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201856:	5775                	li	a4,-3
ffffffffc0201858:	17c1                	addi	a5,a5,-16
ffffffffc020185a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020185e:	8082                	ret
{
ffffffffc0201860:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201862:	00005697          	auipc	a3,0x5
ffffffffc0201866:	d7e68693          	addi	a3,a3,-642 # ffffffffc02065e0 <etext+0xd38>
ffffffffc020186a:	00005617          	auipc	a2,0x5
ffffffffc020186e:	a1e60613          	addi	a2,a2,-1506 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0201872:	06c00593          	li	a1,108
ffffffffc0201876:	00005517          	auipc	a0,0x5
ffffffffc020187a:	a2a50513          	addi	a0,a0,-1494 # ffffffffc02062a0 <etext+0x9f8>
{
ffffffffc020187e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201880:	bcbfe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201884 <default_init_memmap>:
{
ffffffffc0201884:	1141                	addi	sp,sp,-16
ffffffffc0201886:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201888:	c9e1                	beqz	a1,ffffffffc0201958 <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc020188a:	00659713          	slli	a4,a1,0x6
ffffffffc020188e:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201892:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201894:	cf11                	beqz	a4,ffffffffc02018b0 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201896:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201898:	8b05                	andi	a4,a4,1
ffffffffc020189a:	cf59                	beqz	a4,ffffffffc0201938 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020189c:	0007a823          	sw	zero,16(a5)
ffffffffc02018a0:	0007b423          	sd	zero,8(a5)
ffffffffc02018a4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018a8:	04078793          	addi	a5,a5,64
ffffffffc02018ac:	fed795e3          	bne	a5,a3,ffffffffc0201896 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02018b0:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018b2:	4789                	li	a5,2
ffffffffc02018b4:	00850713          	addi	a4,a0,8
ffffffffc02018b8:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018bc:	000b0717          	auipc	a4,0xb0
ffffffffc02018c0:	d3c72703          	lw	a4,-708(a4) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc02018c4:	000b0697          	auipc	a3,0xb0
ffffffffc02018c8:	d2468693          	addi	a3,a3,-732 # ffffffffc02b15e8 <free_area>
    return list->next == list;
ffffffffc02018cc:	669c                	ld	a5,8(a3)
ffffffffc02018ce:	9f2d                	addw	a4,a4,a1
ffffffffc02018d0:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02018d2:	04d78663          	beq	a5,a3,ffffffffc020191e <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc02018d6:	fe878713          	addi	a4,a5,-24
ffffffffc02018da:	4581                	li	a1,0
ffffffffc02018dc:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02018e0:	00e56a63          	bltu	a0,a4,ffffffffc02018f4 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02018e4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02018e6:	02d70263          	beq	a4,a3,ffffffffc020190a <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02018ea:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02018ec:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02018f0:	fee57ae3          	bgeu	a0,a4,ffffffffc02018e4 <default_init_memmap+0x60>
ffffffffc02018f4:	c199                	beqz	a1,ffffffffc02018fa <default_init_memmap+0x76>
ffffffffc02018f6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018fa:	6398                	ld	a4,0(a5)
}
ffffffffc02018fc:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018fe:	e390                	sd	a2,0(a5)
ffffffffc0201900:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0201902:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201904:	f11c                	sd	a5,32(a0)
ffffffffc0201906:	0141                	addi	sp,sp,16
ffffffffc0201908:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020190a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020190c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020190e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201910:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201912:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201914:	00d70e63          	beq	a4,a3,ffffffffc0201930 <default_init_memmap+0xac>
ffffffffc0201918:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020191a:	87ba                	mv	a5,a4
ffffffffc020191c:	bfc1                	j	ffffffffc02018ec <default_init_memmap+0x68>
}
ffffffffc020191e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201920:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201924:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201926:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201928:	e398                	sd	a4,0(a5)
ffffffffc020192a:	e798                	sd	a4,8(a5)
}
ffffffffc020192c:	0141                	addi	sp,sp,16
ffffffffc020192e:	8082                	ret
ffffffffc0201930:	60a2                	ld	ra,8(sp)
ffffffffc0201932:	e290                	sd	a2,0(a3)
ffffffffc0201934:	0141                	addi	sp,sp,16
ffffffffc0201936:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201938:	00005697          	auipc	a3,0x5
ffffffffc020193c:	cd868693          	addi	a3,a3,-808 # ffffffffc0206610 <etext+0xd68>
ffffffffc0201940:	00005617          	auipc	a2,0x5
ffffffffc0201944:	94860613          	addi	a2,a2,-1720 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0201948:	04b00593          	li	a1,75
ffffffffc020194c:	00005517          	auipc	a0,0x5
ffffffffc0201950:	95450513          	addi	a0,a0,-1708 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201954:	af7fe0ef          	jal	ffffffffc020044a <__panic>
    assert(n > 0);
ffffffffc0201958:	00005697          	auipc	a3,0x5
ffffffffc020195c:	c8868693          	addi	a3,a3,-888 # ffffffffc02065e0 <etext+0xd38>
ffffffffc0201960:	00005617          	auipc	a2,0x5
ffffffffc0201964:	92860613          	addi	a2,a2,-1752 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0201968:	04700593          	li	a1,71
ffffffffc020196c:	00005517          	auipc	a0,0x5
ffffffffc0201970:	93450513          	addi	a0,a0,-1740 # ffffffffc02062a0 <etext+0x9f8>
ffffffffc0201974:	ad7fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201978 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201978:	c531                	beqz	a0,ffffffffc02019c4 <slob_free+0x4c>
		return;

	if (size)
ffffffffc020197a:	e9b9                	bnez	a1,ffffffffc02019d0 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020197c:	100027f3          	csrr	a5,sstatus
ffffffffc0201980:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201982:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201984:	efb1                	bnez	a5,ffffffffc02019e0 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201986:	000b0797          	auipc	a5,0xb0
ffffffffc020198a:	8527b783          	ld	a5,-1966(a5) # ffffffffc02b11d8 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020198e:	873e                	mv	a4,a5
ffffffffc0201990:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201992:	02a77a63          	bgeu	a4,a0,ffffffffc02019c6 <slob_free+0x4e>
ffffffffc0201996:	00f56463          	bltu	a0,a5,ffffffffc020199e <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020199a:	fef76ae3          	bltu	a4,a5,ffffffffc020198e <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc020199e:	4110                	lw	a2,0(a0)
ffffffffc02019a0:	00461693          	slli	a3,a2,0x4
ffffffffc02019a4:	96aa                	add	a3,a3,a0
ffffffffc02019a6:	0ad78463          	beq	a5,a3,ffffffffc0201a4e <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02019aa:	4310                	lw	a2,0(a4)
ffffffffc02019ac:	e51c                	sd	a5,8(a0)
ffffffffc02019ae:	00461693          	slli	a3,a2,0x4
ffffffffc02019b2:	96ba                	add	a3,a3,a4
ffffffffc02019b4:	08d50163          	beq	a0,a3,ffffffffc0201a36 <slob_free+0xbe>
ffffffffc02019b8:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc02019ba:	000b0797          	auipc	a5,0xb0
ffffffffc02019be:	80e7bf23          	sd	a4,-2018(a5) # ffffffffc02b11d8 <slobfree>
    if (flag)
ffffffffc02019c2:	e9a5                	bnez	a1,ffffffffc0201a32 <slob_free+0xba>
ffffffffc02019c4:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019c6:	fcf574e3          	bgeu	a0,a5,ffffffffc020198e <slob_free+0x16>
ffffffffc02019ca:	fcf762e3          	bltu	a4,a5,ffffffffc020198e <slob_free+0x16>
ffffffffc02019ce:	bfc1                	j	ffffffffc020199e <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc02019d0:	25bd                	addiw	a1,a1,15
ffffffffc02019d2:	8191                	srli	a1,a1,0x4
ffffffffc02019d4:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019d6:	100027f3          	csrr	a5,sstatus
ffffffffc02019da:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019dc:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019de:	d7c5                	beqz	a5,ffffffffc0201986 <slob_free+0xe>
{
ffffffffc02019e0:	1101                	addi	sp,sp,-32
ffffffffc02019e2:	e42a                	sd	a0,8(sp)
ffffffffc02019e4:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02019e6:	f19fe0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc02019ea:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019ec:	000af797          	auipc	a5,0xaf
ffffffffc02019f0:	7ec7b783          	ld	a5,2028(a5) # ffffffffc02b11d8 <slobfree>
ffffffffc02019f4:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019f6:	873e                	mv	a4,a5
ffffffffc02019f8:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019fa:	06a77663          	bgeu	a4,a0,ffffffffc0201a66 <slob_free+0xee>
ffffffffc02019fe:	00f56463          	bltu	a0,a5,ffffffffc0201a06 <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a02:	fef76ae3          	bltu	a4,a5,ffffffffc02019f6 <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201a06:	4110                	lw	a2,0(a0)
ffffffffc0201a08:	00461693          	slli	a3,a2,0x4
ffffffffc0201a0c:	96aa                	add	a3,a3,a0
ffffffffc0201a0e:	06d78363          	beq	a5,a3,ffffffffc0201a74 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201a12:	4310                	lw	a2,0(a4)
ffffffffc0201a14:	e51c                	sd	a5,8(a0)
ffffffffc0201a16:	00461693          	slli	a3,a2,0x4
ffffffffc0201a1a:	96ba                	add	a3,a3,a4
ffffffffc0201a1c:	06d50163          	beq	a0,a3,ffffffffc0201a7e <slob_free+0x106>
ffffffffc0201a20:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201a22:	000af797          	auipc	a5,0xaf
ffffffffc0201a26:	7ae7bb23          	sd	a4,1974(a5) # ffffffffc02b11d8 <slobfree>
    if (flag)
ffffffffc0201a2a:	e1a9                	bnez	a1,ffffffffc0201a6c <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a2c:	60e2                	ld	ra,24(sp)
ffffffffc0201a2e:	6105                	addi	sp,sp,32
ffffffffc0201a30:	8082                	ret
        intr_enable();
ffffffffc0201a32:	ec7fe06f          	j	ffffffffc02008f8 <intr_enable>
		cur->units += b->units;
ffffffffc0201a36:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201a38:	853e                	mv	a0,a5
ffffffffc0201a3a:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201a3c:	00c687bb          	addw	a5,a3,a2
ffffffffc0201a40:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201a42:	000af797          	auipc	a5,0xaf
ffffffffc0201a46:	78e7bb23          	sd	a4,1942(a5) # ffffffffc02b11d8 <slobfree>
    if (flag)
ffffffffc0201a4a:	ddad                	beqz	a1,ffffffffc02019c4 <slob_free+0x4c>
ffffffffc0201a4c:	b7dd                	j	ffffffffc0201a32 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201a4e:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a50:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201a52:	9eb1                	addw	a3,a3,a2
ffffffffc0201a54:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201a56:	4310                	lw	a2,0(a4)
ffffffffc0201a58:	e51c                	sd	a5,8(a0)
ffffffffc0201a5a:	00461693          	slli	a3,a2,0x4
ffffffffc0201a5e:	96ba                	add	a3,a3,a4
ffffffffc0201a60:	f4d51ce3          	bne	a0,a3,ffffffffc02019b8 <slob_free+0x40>
ffffffffc0201a64:	bfc9                	j	ffffffffc0201a36 <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a66:	f8f56ee3          	bltu	a0,a5,ffffffffc0201a02 <slob_free+0x8a>
ffffffffc0201a6a:	b771                	j	ffffffffc02019f6 <slob_free+0x7e>
}
ffffffffc0201a6c:	60e2                	ld	ra,24(sp)
ffffffffc0201a6e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201a70:	e89fe06f          	j	ffffffffc02008f8 <intr_enable>
		b->units += cur->next->units;
ffffffffc0201a74:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a76:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201a78:	9eb1                	addw	a3,a3,a2
ffffffffc0201a7a:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201a7c:	bf59                	j	ffffffffc0201a12 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201a7e:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201a80:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201a82:	00c687bb          	addw	a5,a3,a2
ffffffffc0201a86:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201a88:	bf61                	j	ffffffffc0201a20 <slob_free+0xa8>

ffffffffc0201a8a <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a8a:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a8c:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a8e:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a92:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a94:	32a000ef          	jal	ffffffffc0201dbe <alloc_pages>
	if (!page)
ffffffffc0201a98:	c91d                	beqz	a0,ffffffffc0201ace <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201a9a:	000b4697          	auipc	a3,0xb4
ffffffffc0201a9e:	bf66b683          	ld	a3,-1034(a3) # ffffffffc02b5690 <pages>
ffffffffc0201aa2:	00006797          	auipc	a5,0x6
ffffffffc0201aa6:	6767b783          	ld	a5,1654(a5) # ffffffffc0208118 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201aaa:	000b4717          	auipc	a4,0xb4
ffffffffc0201aae:	bde73703          	ld	a4,-1058(a4) # ffffffffc02b5688 <npage>
    return page - pages + nbase;
ffffffffc0201ab2:	8d15                	sub	a0,a0,a3
ffffffffc0201ab4:	8519                	srai	a0,a0,0x6
ffffffffc0201ab6:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201ab8:	00c51793          	slli	a5,a0,0xc
ffffffffc0201abc:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201abe:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201ac0:	00e7fa63          	bgeu	a5,a4,ffffffffc0201ad4 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201ac4:	000b4797          	auipc	a5,0xb4
ffffffffc0201ac8:	bbc7b783          	ld	a5,-1092(a5) # ffffffffc02b5680 <va_pa_offset>
ffffffffc0201acc:	953e                	add	a0,a0,a5
}
ffffffffc0201ace:	60a2                	ld	ra,8(sp)
ffffffffc0201ad0:	0141                	addi	sp,sp,16
ffffffffc0201ad2:	8082                	ret
ffffffffc0201ad4:	86aa                	mv	a3,a0
ffffffffc0201ad6:	00005617          	auipc	a2,0x5
ffffffffc0201ada:	b6260613          	addi	a2,a2,-1182 # ffffffffc0206638 <etext+0xd90>
ffffffffc0201ade:	07100593          	li	a1,113
ffffffffc0201ae2:	00005517          	auipc	a0,0x5
ffffffffc0201ae6:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0201aea:	961fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201aee <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201aee:	7179                	addi	sp,sp,-48
ffffffffc0201af0:	f406                	sd	ra,40(sp)
ffffffffc0201af2:	f022                	sd	s0,32(sp)
ffffffffc0201af4:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201af6:	01050713          	addi	a4,a0,16
ffffffffc0201afa:	6785                	lui	a5,0x1
ffffffffc0201afc:	0af77e63          	bgeu	a4,a5,ffffffffc0201bb8 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b00:	00f50413          	addi	s0,a0,15
ffffffffc0201b04:	8011                	srli	s0,s0,0x4
ffffffffc0201b06:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b08:	100025f3          	csrr	a1,sstatus
ffffffffc0201b0c:	8989                	andi	a1,a1,2
ffffffffc0201b0e:	edd1                	bnez	a1,ffffffffc0201baa <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201b10:	000af497          	auipc	s1,0xaf
ffffffffc0201b14:	6c848493          	addi	s1,s1,1736 # ffffffffc02b11d8 <slobfree>
ffffffffc0201b18:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b1a:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201b1c:	4314                	lw	a3,0(a4)
ffffffffc0201b1e:	0886da63          	bge	a3,s0,ffffffffc0201bb2 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201b22:	00e60a63          	beq	a2,a4,ffffffffc0201b36 <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b26:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201b28:	4394                	lw	a3,0(a5)
ffffffffc0201b2a:	0286d863          	bge	a3,s0,ffffffffc0201b5a <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201b2e:	6090                	ld	a2,0(s1)
ffffffffc0201b30:	873e                	mv	a4,a5
ffffffffc0201b32:	fee61ae3          	bne	a2,a4,ffffffffc0201b26 <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201b36:	e9b1                	bnez	a1,ffffffffc0201b8a <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b38:	4501                	li	a0,0
ffffffffc0201b3a:	f51ff0ef          	jal	ffffffffc0201a8a <__slob_get_free_pages.constprop.0>
ffffffffc0201b3e:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201b40:	c915                	beqz	a0,ffffffffc0201b74 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b42:	6585                	lui	a1,0x1
ffffffffc0201b44:	e35ff0ef          	jal	ffffffffc0201978 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b48:	100025f3          	csrr	a1,sstatus
ffffffffc0201b4c:	8989                	andi	a1,a1,2
ffffffffc0201b4e:	e98d                	bnez	a1,ffffffffc0201b80 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201b50:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b52:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201b54:	4394                	lw	a3,0(a5)
ffffffffc0201b56:	fc86cce3          	blt	a3,s0,ffffffffc0201b2e <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201b5a:	04d40563          	beq	s0,a3,ffffffffc0201ba4 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201b5e:	00441613          	slli	a2,s0,0x4
ffffffffc0201b62:	963e                	add	a2,a2,a5
ffffffffc0201b64:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201b66:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201b68:	9e81                	subw	a3,a3,s0
ffffffffc0201b6a:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201b6c:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201b6e:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201b70:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201b72:	ed99                	bnez	a1,ffffffffc0201b90 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201b74:	70a2                	ld	ra,40(sp)
ffffffffc0201b76:	7402                	ld	s0,32(sp)
ffffffffc0201b78:	64e2                	ld	s1,24(sp)
ffffffffc0201b7a:	853e                	mv	a0,a5
ffffffffc0201b7c:	6145                	addi	sp,sp,48
ffffffffc0201b7e:	8082                	ret
        intr_disable();
ffffffffc0201b80:	d7ffe0ef          	jal	ffffffffc02008fe <intr_disable>
			cur = slobfree;
ffffffffc0201b84:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201b86:	4585                	li	a1,1
ffffffffc0201b88:	b7e9                	j	ffffffffc0201b52 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201b8a:	d6ffe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201b8e:	b76d                	j	ffffffffc0201b38 <slob_alloc.constprop.0+0x4a>
ffffffffc0201b90:	e43e                	sd	a5,8(sp)
ffffffffc0201b92:	d67fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201b96:	67a2                	ld	a5,8(sp)
}
ffffffffc0201b98:	70a2                	ld	ra,40(sp)
ffffffffc0201b9a:	7402                	ld	s0,32(sp)
ffffffffc0201b9c:	64e2                	ld	s1,24(sp)
ffffffffc0201b9e:	853e                	mv	a0,a5
ffffffffc0201ba0:	6145                	addi	sp,sp,48
ffffffffc0201ba2:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201ba4:	6794                	ld	a3,8(a5)
ffffffffc0201ba6:	e714                	sd	a3,8(a4)
ffffffffc0201ba8:	b7e1                	j	ffffffffc0201b70 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201baa:	d55fe0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0201bae:	4585                	li	a1,1
ffffffffc0201bb0:	b785                	j	ffffffffc0201b10 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bb2:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201bb4:	8732                	mv	a4,a2
ffffffffc0201bb6:	b755                	j	ffffffffc0201b5a <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bb8:	00005697          	auipc	a3,0x5
ffffffffc0201bbc:	ab868693          	addi	a3,a3,-1352 # ffffffffc0206670 <etext+0xdc8>
ffffffffc0201bc0:	00004617          	auipc	a2,0x4
ffffffffc0201bc4:	6c860613          	addi	a2,a2,1736 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0201bc8:	06400593          	li	a1,100
ffffffffc0201bcc:	00005517          	auipc	a0,0x5
ffffffffc0201bd0:	ac450513          	addi	a0,a0,-1340 # ffffffffc0206690 <etext+0xde8>
ffffffffc0201bd4:	877fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201bd8 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201bd8:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201bda:	00005517          	auipc	a0,0x5
ffffffffc0201bde:	ace50513          	addi	a0,a0,-1330 # ffffffffc02066a8 <etext+0xe00>
{
ffffffffc0201be2:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201be4:	db4fe0ef          	jal	ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201be8:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201bea:	00005517          	auipc	a0,0x5
ffffffffc0201bee:	ad650513          	addi	a0,a0,-1322 # ffffffffc02066c0 <etext+0xe18>
}
ffffffffc0201bf2:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201bf4:	da4fe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201bf8 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201bf8:	4501                	li	a0,0
ffffffffc0201bfa:	8082                	ret

ffffffffc0201bfc <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201bfc:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bfe:	6685                	lui	a3,0x1
{
ffffffffc0201c00:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c02:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7f39>
ffffffffc0201c04:	04a6f963          	bgeu	a3,a0,ffffffffc0201c56 <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c08:	e42a                	sd	a0,8(sp)
ffffffffc0201c0a:	4561                	li	a0,24
ffffffffc0201c0c:	e822                	sd	s0,16(sp)
ffffffffc0201c0e:	ee1ff0ef          	jal	ffffffffc0201aee <slob_alloc.constprop.0>
ffffffffc0201c12:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201c14:	c541                	beqz	a0,ffffffffc0201c9c <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201c16:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201c18:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201c1a:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201c1c:	00f75763          	bge	a4,a5,ffffffffc0201c2a <kmalloc+0x2e>
ffffffffc0201c20:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201c24:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201c26:	fef74de3          	blt	a4,a5,ffffffffc0201c20 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201c2a:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c2c:	e5fff0ef          	jal	ffffffffc0201a8a <__slob_get_free_pages.constprop.0>
ffffffffc0201c30:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201c32:	cd31                	beqz	a0,ffffffffc0201c8e <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c34:	100027f3          	csrr	a5,sstatus
ffffffffc0201c38:	8b89                	andi	a5,a5,2
ffffffffc0201c3a:	eb85                	bnez	a5,ffffffffc0201c6a <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201c3c:	000b4797          	auipc	a5,0xb4
ffffffffc0201c40:	a247b783          	ld	a5,-1500(a5) # ffffffffc02b5660 <bigblocks>
		bigblocks = bb;
ffffffffc0201c44:	000b4717          	auipc	a4,0xb4
ffffffffc0201c48:	a0873e23          	sd	s0,-1508(a4) # ffffffffc02b5660 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201c4c:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201c4e:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201c50:	60e2                	ld	ra,24(sp)
ffffffffc0201c52:	6105                	addi	sp,sp,32
ffffffffc0201c54:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201c56:	0541                	addi	a0,a0,16
ffffffffc0201c58:	e97ff0ef          	jal	ffffffffc0201aee <slob_alloc.constprop.0>
ffffffffc0201c5c:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201c5e:	0541                	addi	a0,a0,16
ffffffffc0201c60:	fbe5                	bnez	a5,ffffffffc0201c50 <kmalloc+0x54>
		return 0;
ffffffffc0201c62:	4501                	li	a0,0
}
ffffffffc0201c64:	60e2                	ld	ra,24(sp)
ffffffffc0201c66:	6105                	addi	sp,sp,32
ffffffffc0201c68:	8082                	ret
        intr_disable();
ffffffffc0201c6a:	c95fe0ef          	jal	ffffffffc02008fe <intr_disable>
		bb->next = bigblocks;
ffffffffc0201c6e:	000b4797          	auipc	a5,0xb4
ffffffffc0201c72:	9f27b783          	ld	a5,-1550(a5) # ffffffffc02b5660 <bigblocks>
		bigblocks = bb;
ffffffffc0201c76:	000b4717          	auipc	a4,0xb4
ffffffffc0201c7a:	9e873523          	sd	s0,-1558(a4) # ffffffffc02b5660 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201c7e:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201c80:	c79fe0ef          	jal	ffffffffc02008f8 <intr_enable>
		return bb->pages;
ffffffffc0201c84:	6408                	ld	a0,8(s0)
}
ffffffffc0201c86:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201c88:	6442                	ld	s0,16(sp)
}
ffffffffc0201c8a:	6105                	addi	sp,sp,32
ffffffffc0201c8c:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c8e:	8522                	mv	a0,s0
ffffffffc0201c90:	45e1                	li	a1,24
ffffffffc0201c92:	ce7ff0ef          	jal	ffffffffc0201978 <slob_free>
		return 0;
ffffffffc0201c96:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c98:	6442                	ld	s0,16(sp)
ffffffffc0201c9a:	b7e9                	j	ffffffffc0201c64 <kmalloc+0x68>
ffffffffc0201c9c:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201c9e:	4501                	li	a0,0
ffffffffc0201ca0:	b7d1                	j	ffffffffc0201c64 <kmalloc+0x68>

ffffffffc0201ca2 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201ca2:	c571                	beqz	a0,ffffffffc0201d6e <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201ca4:	03451793          	slli	a5,a0,0x34
ffffffffc0201ca8:	e3e1                	bnez	a5,ffffffffc0201d68 <kfree+0xc6>
{
ffffffffc0201caa:	1101                	addi	sp,sp,-32
ffffffffc0201cac:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cae:	100027f3          	csrr	a5,sstatus
ffffffffc0201cb2:	8b89                	andi	a5,a5,2
ffffffffc0201cb4:	e7c1                	bnez	a5,ffffffffc0201d3c <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cb6:	000b4797          	auipc	a5,0xb4
ffffffffc0201cba:	9aa7b783          	ld	a5,-1622(a5) # ffffffffc02b5660 <bigblocks>
    return 0;
ffffffffc0201cbe:	4581                	li	a1,0
ffffffffc0201cc0:	cbad                	beqz	a5,ffffffffc0201d32 <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201cc2:	000b4617          	auipc	a2,0xb4
ffffffffc0201cc6:	99e60613          	addi	a2,a2,-1634 # ffffffffc02b5660 <bigblocks>
ffffffffc0201cca:	a021                	j	ffffffffc0201cd2 <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201ccc:	01070613          	addi	a2,a4,16
ffffffffc0201cd0:	c3a5                	beqz	a5,ffffffffc0201d30 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201cd2:	6794                	ld	a3,8(a5)
ffffffffc0201cd4:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201cd6:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201cd8:	fea69ae3          	bne	a3,a0,ffffffffc0201ccc <kfree+0x2a>
				*last = bb->next;
ffffffffc0201cdc:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201cde:	edb5                	bnez	a1,ffffffffc0201d5a <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201ce0:	c02007b7          	lui	a5,0xc0200
ffffffffc0201ce4:	0af56263          	bltu	a0,a5,ffffffffc0201d88 <kfree+0xe6>
ffffffffc0201ce8:	000b4797          	auipc	a5,0xb4
ffffffffc0201cec:	9987b783          	ld	a5,-1640(a5) # ffffffffc02b5680 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201cf0:	000b4697          	auipc	a3,0xb4
ffffffffc0201cf4:	9986b683          	ld	a3,-1640(a3) # ffffffffc02b5688 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201cf8:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201cfa:	00c55793          	srli	a5,a0,0xc
ffffffffc0201cfe:	06d7f963          	bgeu	a5,a3,ffffffffc0201d70 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d02:	00006617          	auipc	a2,0x6
ffffffffc0201d06:	41663603          	ld	a2,1046(a2) # ffffffffc0208118 <nbase>
ffffffffc0201d0a:	000b4517          	auipc	a0,0xb4
ffffffffc0201d0e:	98653503          	ld	a0,-1658(a0) # ffffffffc02b5690 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201d12:	4314                	lw	a3,0(a4)
ffffffffc0201d14:	8f91                	sub	a5,a5,a2
ffffffffc0201d16:	079a                	slli	a5,a5,0x6
ffffffffc0201d18:	4585                	li	a1,1
ffffffffc0201d1a:	953e                	add	a0,a0,a5
ffffffffc0201d1c:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201d20:	e03a                	sd	a4,0(sp)
ffffffffc0201d22:	0d6000ef          	jal	ffffffffc0201df8 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d26:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d28:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d2a:	45e1                	li	a1,24
}
ffffffffc0201d2c:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d2e:	b1a9                	j	ffffffffc0201978 <slob_free>
ffffffffc0201d30:	e185                	bnez	a1,ffffffffc0201d50 <kfree+0xae>
}
ffffffffc0201d32:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d34:	1541                	addi	a0,a0,-16
ffffffffc0201d36:	4581                	li	a1,0
}
ffffffffc0201d38:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d3a:	b93d                	j	ffffffffc0201978 <slob_free>
        intr_disable();
ffffffffc0201d3c:	e02a                	sd	a0,0(sp)
ffffffffc0201d3e:	bc1fe0ef          	jal	ffffffffc02008fe <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d42:	000b4797          	auipc	a5,0xb4
ffffffffc0201d46:	91e7b783          	ld	a5,-1762(a5) # ffffffffc02b5660 <bigblocks>
ffffffffc0201d4a:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201d4c:	4585                	li	a1,1
ffffffffc0201d4e:	fbb5                	bnez	a5,ffffffffc0201cc2 <kfree+0x20>
ffffffffc0201d50:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201d52:	ba7fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201d56:	6502                	ld	a0,0(sp)
ffffffffc0201d58:	bfe9                	j	ffffffffc0201d32 <kfree+0x90>
ffffffffc0201d5a:	e42a                	sd	a0,8(sp)
ffffffffc0201d5c:	e03a                	sd	a4,0(sp)
ffffffffc0201d5e:	b9bfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201d62:	6522                	ld	a0,8(sp)
ffffffffc0201d64:	6702                	ld	a4,0(sp)
ffffffffc0201d66:	bfad                	j	ffffffffc0201ce0 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d68:	1541                	addi	a0,a0,-16
ffffffffc0201d6a:	4581                	li	a1,0
ffffffffc0201d6c:	b131                	j	ffffffffc0201978 <slob_free>
ffffffffc0201d6e:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201d70:	00005617          	auipc	a2,0x5
ffffffffc0201d74:	99860613          	addi	a2,a2,-1640 # ffffffffc0206708 <etext+0xe60>
ffffffffc0201d78:	06900593          	li	a1,105
ffffffffc0201d7c:	00005517          	auipc	a0,0x5
ffffffffc0201d80:	8e450513          	addi	a0,a0,-1820 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0201d84:	ec6fe0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201d88:	86aa                	mv	a3,a0
ffffffffc0201d8a:	00005617          	auipc	a2,0x5
ffffffffc0201d8e:	95660613          	addi	a2,a2,-1706 # ffffffffc02066e0 <etext+0xe38>
ffffffffc0201d92:	07700593          	li	a1,119
ffffffffc0201d96:	00005517          	auipc	a0,0x5
ffffffffc0201d9a:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0201d9e:	eacfe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201da2 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201da2:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201da4:	00005617          	auipc	a2,0x5
ffffffffc0201da8:	96460613          	addi	a2,a2,-1692 # ffffffffc0206708 <etext+0xe60>
ffffffffc0201dac:	06900593          	li	a1,105
ffffffffc0201db0:	00005517          	auipc	a0,0x5
ffffffffc0201db4:	8b050513          	addi	a0,a0,-1872 # ffffffffc0206660 <etext+0xdb8>
pa2page(uintptr_t pa)
ffffffffc0201db8:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201dba:	e90fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201dbe <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dbe:	100027f3          	csrr	a5,sstatus
ffffffffc0201dc2:	8b89                	andi	a5,a5,2
ffffffffc0201dc4:	e799                	bnez	a5,ffffffffc0201dd2 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dc6:	000b4797          	auipc	a5,0xb4
ffffffffc0201dca:	8a27b783          	ld	a5,-1886(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201dce:	6f9c                	ld	a5,24(a5)
ffffffffc0201dd0:	8782                	jr	a5
{
ffffffffc0201dd2:	1101                	addi	sp,sp,-32
ffffffffc0201dd4:	ec06                	sd	ra,24(sp)
ffffffffc0201dd6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201dd8:	b27fe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ddc:	000b4797          	auipc	a5,0xb4
ffffffffc0201de0:	88c7b783          	ld	a5,-1908(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201de4:	6522                	ld	a0,8(sp)
ffffffffc0201de6:	6f9c                	ld	a5,24(a5)
ffffffffc0201de8:	9782                	jalr	a5
ffffffffc0201dea:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201dec:	b0dfe0ef          	jal	ffffffffc02008f8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201df0:	60e2                	ld	ra,24(sp)
ffffffffc0201df2:	6522                	ld	a0,8(sp)
ffffffffc0201df4:	6105                	addi	sp,sp,32
ffffffffc0201df6:	8082                	ret

ffffffffc0201df8 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201df8:	100027f3          	csrr	a5,sstatus
ffffffffc0201dfc:	8b89                	andi	a5,a5,2
ffffffffc0201dfe:	e799                	bnez	a5,ffffffffc0201e0c <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201e00:	000b4797          	auipc	a5,0xb4
ffffffffc0201e04:	8687b783          	ld	a5,-1944(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201e08:	739c                	ld	a5,32(a5)
ffffffffc0201e0a:	8782                	jr	a5
{
ffffffffc0201e0c:	1101                	addi	sp,sp,-32
ffffffffc0201e0e:	ec06                	sd	ra,24(sp)
ffffffffc0201e10:	e42e                	sd	a1,8(sp)
ffffffffc0201e12:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201e14:	aebfe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201e18:	000b4797          	auipc	a5,0xb4
ffffffffc0201e1c:	8507b783          	ld	a5,-1968(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201e20:	65a2                	ld	a1,8(sp)
ffffffffc0201e22:	6502                	ld	a0,0(sp)
ffffffffc0201e24:	739c                	ld	a5,32(a5)
ffffffffc0201e26:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201e28:	60e2                	ld	ra,24(sp)
ffffffffc0201e2a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201e2c:	acdfe06f          	j	ffffffffc02008f8 <intr_enable>

ffffffffc0201e30 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e30:	100027f3          	csrr	a5,sstatus
ffffffffc0201e34:	8b89                	andi	a5,a5,2
ffffffffc0201e36:	e799                	bnez	a5,ffffffffc0201e44 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e38:	000b4797          	auipc	a5,0xb4
ffffffffc0201e3c:	8307b783          	ld	a5,-2000(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201e40:	779c                	ld	a5,40(a5)
ffffffffc0201e42:	8782                	jr	a5
{
ffffffffc0201e44:	1101                	addi	sp,sp,-32
ffffffffc0201e46:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201e48:	ab7fe0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e4c:	000b4797          	auipc	a5,0xb4
ffffffffc0201e50:	81c7b783          	ld	a5,-2020(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201e54:	779c                	ld	a5,40(a5)
ffffffffc0201e56:	9782                	jalr	a5
ffffffffc0201e58:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201e5a:	a9ffe0ef          	jal	ffffffffc02008f8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201e5e:	60e2                	ld	ra,24(sp)
ffffffffc0201e60:	6522                	ld	a0,8(sp)
ffffffffc0201e62:	6105                	addi	sp,sp,32
ffffffffc0201e64:	8082                	ret

ffffffffc0201e66 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e66:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e6a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e6e:	078e                	slli	a5,a5,0x3
ffffffffc0201e70:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201e74:	6314                	ld	a3,0(a4)
{
ffffffffc0201e76:	7139                	addi	sp,sp,-64
ffffffffc0201e78:	f822                	sd	s0,48(sp)
ffffffffc0201e7a:	f426                	sd	s1,40(sp)
ffffffffc0201e7c:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201e7e:	0016f793          	andi	a5,a3,1
{
ffffffffc0201e82:	842e                	mv	s0,a1
ffffffffc0201e84:	8832                	mv	a6,a2
ffffffffc0201e86:	000b4497          	auipc	s1,0xb4
ffffffffc0201e8a:	80248493          	addi	s1,s1,-2046 # ffffffffc02b5688 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201e8e:	ebd1                	bnez	a5,ffffffffc0201f22 <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e90:	16060d63          	beqz	a2,ffffffffc020200a <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e94:	100027f3          	csrr	a5,sstatus
ffffffffc0201e98:	8b89                	andi	a5,a5,2
ffffffffc0201e9a:	16079e63          	bnez	a5,ffffffffc0202016 <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e9e:	000b3797          	auipc	a5,0xb3
ffffffffc0201ea2:	7ca7b783          	ld	a5,1994(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201ea6:	4505                	li	a0,1
ffffffffc0201ea8:	e43a                	sd	a4,8(sp)
ffffffffc0201eaa:	6f9c                	ld	a5,24(a5)
ffffffffc0201eac:	e832                	sd	a2,16(sp)
ffffffffc0201eae:	9782                	jalr	a5
ffffffffc0201eb0:	6722                	ld	a4,8(sp)
ffffffffc0201eb2:	6842                	ld	a6,16(sp)
ffffffffc0201eb4:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201eb6:	14078a63          	beqz	a5,ffffffffc020200a <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201eba:	000b3517          	auipc	a0,0xb3
ffffffffc0201ebe:	7d653503          	ld	a0,2006(a0) # ffffffffc02b5690 <pages>
ffffffffc0201ec2:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ec6:	000b3497          	auipc	s1,0xb3
ffffffffc0201eca:	7c248493          	addi	s1,s1,1986 # ffffffffc02b5688 <npage>
ffffffffc0201ece:	40a78533          	sub	a0,a5,a0
ffffffffc0201ed2:	8519                	srai	a0,a0,0x6
ffffffffc0201ed4:	9546                	add	a0,a0,a7
ffffffffc0201ed6:	6090                	ld	a2,0(s1)
ffffffffc0201ed8:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201edc:	4585                	li	a1,1
ffffffffc0201ede:	82b1                	srli	a3,a3,0xc
ffffffffc0201ee0:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ee2:	0532                	slli	a0,a0,0xc
ffffffffc0201ee4:	1ac6f763          	bgeu	a3,a2,ffffffffc0202092 <get_pte+0x22c>
ffffffffc0201ee8:	000b3697          	auipc	a3,0xb3
ffffffffc0201eec:	7986b683          	ld	a3,1944(a3) # ffffffffc02b5680 <va_pa_offset>
ffffffffc0201ef0:	6605                	lui	a2,0x1
ffffffffc0201ef2:	4581                	li	a1,0
ffffffffc0201ef4:	9536                	add	a0,a0,a3
ffffffffc0201ef6:	ec42                	sd	a6,24(sp)
ffffffffc0201ef8:	e83e                	sd	a5,16(sp)
ffffffffc0201efa:	e43a                	sd	a4,8(sp)
ffffffffc0201efc:	183030ef          	jal	ffffffffc020587e <memset>
    return page - pages + nbase;
ffffffffc0201f00:	000b3697          	auipc	a3,0xb3
ffffffffc0201f04:	7906b683          	ld	a3,1936(a3) # ffffffffc02b5690 <pages>
ffffffffc0201f08:	67c2                	ld	a5,16(sp)
ffffffffc0201f0a:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f0e:	6722                	ld	a4,8(sp)
ffffffffc0201f10:	40d786b3          	sub	a3,a5,a3
ffffffffc0201f14:	8699                	srai	a3,a3,0x6
ffffffffc0201f16:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f18:	06aa                	slli	a3,a3,0xa
ffffffffc0201f1a:	6862                	ld	a6,24(sp)
ffffffffc0201f1c:	0116e693          	ori	a3,a3,17
ffffffffc0201f20:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f22:	c006f693          	andi	a3,a3,-1024
ffffffffc0201f26:	6098                	ld	a4,0(s1)
ffffffffc0201f28:	068a                	slli	a3,a3,0x2
ffffffffc0201f2a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f2e:	14e7f663          	bgeu	a5,a4,ffffffffc020207a <get_pte+0x214>
ffffffffc0201f32:	000b3897          	auipc	a7,0xb3
ffffffffc0201f36:	74e88893          	addi	a7,a7,1870 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0201f3a:	0008b603          	ld	a2,0(a7)
ffffffffc0201f3e:	01545793          	srli	a5,s0,0x15
ffffffffc0201f42:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f46:	96b2                	add	a3,a3,a2
ffffffffc0201f48:	078e                	slli	a5,a5,0x3
ffffffffc0201f4a:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201f4c:	6394                	ld	a3,0(a5)
ffffffffc0201f4e:	0016f613          	andi	a2,a3,1
ffffffffc0201f52:	e659                	bnez	a2,ffffffffc0201fe0 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f54:	0a080b63          	beqz	a6,ffffffffc020200a <get_pte+0x1a4>
ffffffffc0201f58:	10002773          	csrr	a4,sstatus
ffffffffc0201f5c:	8b09                	andi	a4,a4,2
ffffffffc0201f5e:	ef71                	bnez	a4,ffffffffc020203a <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f60:	000b3717          	auipc	a4,0xb3
ffffffffc0201f64:	70873703          	ld	a4,1800(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201f68:	4505                	li	a0,1
ffffffffc0201f6a:	e43e                	sd	a5,8(sp)
ffffffffc0201f6c:	6f18                	ld	a4,24(a4)
ffffffffc0201f6e:	9702                	jalr	a4
ffffffffc0201f70:	67a2                	ld	a5,8(sp)
ffffffffc0201f72:	872a                	mv	a4,a0
ffffffffc0201f74:	000b3897          	auipc	a7,0xb3
ffffffffc0201f78:	70c88893          	addi	a7,a7,1804 # ffffffffc02b5680 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f7c:	c759                	beqz	a4,ffffffffc020200a <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201f7e:	000b3697          	auipc	a3,0xb3
ffffffffc0201f82:	7126b683          	ld	a3,1810(a3) # ffffffffc02b5690 <pages>
ffffffffc0201f86:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f8a:	608c                	ld	a1,0(s1)
ffffffffc0201f8c:	40d706b3          	sub	a3,a4,a3
ffffffffc0201f90:	8699                	srai	a3,a3,0x6
ffffffffc0201f92:	96c2                	add	a3,a3,a6
ffffffffc0201f94:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0201f98:	4505                	li	a0,1
ffffffffc0201f9a:	8231                	srli	a2,a2,0xc
ffffffffc0201f9c:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f9e:	06b2                	slli	a3,a3,0xc
ffffffffc0201fa0:	10b67663          	bgeu	a2,a1,ffffffffc02020ac <get_pte+0x246>
ffffffffc0201fa4:	0008b503          	ld	a0,0(a7)
ffffffffc0201fa8:	6605                	lui	a2,0x1
ffffffffc0201faa:	4581                	li	a1,0
ffffffffc0201fac:	9536                	add	a0,a0,a3
ffffffffc0201fae:	e83a                	sd	a4,16(sp)
ffffffffc0201fb0:	e43e                	sd	a5,8(sp)
ffffffffc0201fb2:	0cd030ef          	jal	ffffffffc020587e <memset>
    return page - pages + nbase;
ffffffffc0201fb6:	000b3697          	auipc	a3,0xb3
ffffffffc0201fba:	6da6b683          	ld	a3,1754(a3) # ffffffffc02b5690 <pages>
ffffffffc0201fbe:	6742                	ld	a4,16(sp)
ffffffffc0201fc0:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fc4:	67a2                	ld	a5,8(sp)
ffffffffc0201fc6:	40d706b3          	sub	a3,a4,a3
ffffffffc0201fca:	8699                	srai	a3,a3,0x6
ffffffffc0201fcc:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fce:	06aa                	slli	a3,a3,0xa
ffffffffc0201fd0:	0116e693          	ori	a3,a3,17
ffffffffc0201fd4:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201fd6:	6098                	ld	a4,0(s1)
ffffffffc0201fd8:	000b3897          	auipc	a7,0xb3
ffffffffc0201fdc:	6a888893          	addi	a7,a7,1704 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0201fe0:	c006f693          	andi	a3,a3,-1024
ffffffffc0201fe4:	068a                	slli	a3,a3,0x2
ffffffffc0201fe6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fea:	06e7fc63          	bgeu	a5,a4,ffffffffc0202062 <get_pte+0x1fc>
ffffffffc0201fee:	0008b783          	ld	a5,0(a7)
ffffffffc0201ff2:	8031                	srli	s0,s0,0xc
ffffffffc0201ff4:	1ff47413          	andi	s0,s0,511
ffffffffc0201ff8:	040e                	slli	s0,s0,0x3
ffffffffc0201ffa:	96be                	add	a3,a3,a5
}
ffffffffc0201ffc:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ffe:	00868533          	add	a0,a3,s0
}
ffffffffc0202002:	7442                	ld	s0,48(sp)
ffffffffc0202004:	74a2                	ld	s1,40(sp)
ffffffffc0202006:	6121                	addi	sp,sp,64
ffffffffc0202008:	8082                	ret
ffffffffc020200a:	70e2                	ld	ra,56(sp)
ffffffffc020200c:	7442                	ld	s0,48(sp)
ffffffffc020200e:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0202010:	4501                	li	a0,0
}
ffffffffc0202012:	6121                	addi	sp,sp,64
ffffffffc0202014:	8082                	ret
        intr_disable();
ffffffffc0202016:	e83a                	sd	a4,16(sp)
ffffffffc0202018:	ec32                	sd	a2,24(sp)
ffffffffc020201a:	8e5fe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020201e:	000b3797          	auipc	a5,0xb3
ffffffffc0202022:	64a7b783          	ld	a5,1610(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202026:	4505                	li	a0,1
ffffffffc0202028:	6f9c                	ld	a5,24(a5)
ffffffffc020202a:	9782                	jalr	a5
ffffffffc020202c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020202e:	8cbfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202032:	6862                	ld	a6,24(sp)
ffffffffc0202034:	6742                	ld	a4,16(sp)
ffffffffc0202036:	67a2                	ld	a5,8(sp)
ffffffffc0202038:	bdbd                	j	ffffffffc0201eb6 <get_pte+0x50>
        intr_disable();
ffffffffc020203a:	e83e                	sd	a5,16(sp)
ffffffffc020203c:	8c3fe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202040:	000b3717          	auipc	a4,0xb3
ffffffffc0202044:	62873703          	ld	a4,1576(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202048:	4505                	li	a0,1
ffffffffc020204a:	6f18                	ld	a4,24(a4)
ffffffffc020204c:	9702                	jalr	a4
ffffffffc020204e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202050:	8a9fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202054:	6722                	ld	a4,8(sp)
ffffffffc0202056:	67c2                	ld	a5,16(sp)
ffffffffc0202058:	000b3897          	auipc	a7,0xb3
ffffffffc020205c:	62888893          	addi	a7,a7,1576 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0202060:	bf31                	j	ffffffffc0201f7c <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202062:	00004617          	auipc	a2,0x4
ffffffffc0202066:	5d660613          	addi	a2,a2,1494 # ffffffffc0206638 <etext+0xd90>
ffffffffc020206a:	0fa00593          	li	a1,250
ffffffffc020206e:	00004517          	auipc	a0,0x4
ffffffffc0202072:	6ba50513          	addi	a0,a0,1722 # ffffffffc0206728 <etext+0xe80>
ffffffffc0202076:	bd4fe0ef          	jal	ffffffffc020044a <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020207a:	00004617          	auipc	a2,0x4
ffffffffc020207e:	5be60613          	addi	a2,a2,1470 # ffffffffc0206638 <etext+0xd90>
ffffffffc0202082:	0ed00593          	li	a1,237
ffffffffc0202086:	00004517          	auipc	a0,0x4
ffffffffc020208a:	6a250513          	addi	a0,a0,1698 # ffffffffc0206728 <etext+0xe80>
ffffffffc020208e:	bbcfe0ef          	jal	ffffffffc020044a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202092:	86aa                	mv	a3,a0
ffffffffc0202094:	00004617          	auipc	a2,0x4
ffffffffc0202098:	5a460613          	addi	a2,a2,1444 # ffffffffc0206638 <etext+0xd90>
ffffffffc020209c:	0e900593          	li	a1,233
ffffffffc02020a0:	00004517          	auipc	a0,0x4
ffffffffc02020a4:	68850513          	addi	a0,a0,1672 # ffffffffc0206728 <etext+0xe80>
ffffffffc02020a8:	ba2fe0ef          	jal	ffffffffc020044a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020ac:	00004617          	auipc	a2,0x4
ffffffffc02020b0:	58c60613          	addi	a2,a2,1420 # ffffffffc0206638 <etext+0xd90>
ffffffffc02020b4:	0f700593          	li	a1,247
ffffffffc02020b8:	00004517          	auipc	a0,0x4
ffffffffc02020bc:	67050513          	addi	a0,a0,1648 # ffffffffc0206728 <etext+0xe80>
ffffffffc02020c0:	b8afe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02020c4 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02020c4:	1141                	addi	sp,sp,-16
ffffffffc02020c6:	e022                	sd	s0,0(sp)
ffffffffc02020c8:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020ca:	4601                	li	a2,0
{
ffffffffc02020cc:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020ce:	d99ff0ef          	jal	ffffffffc0201e66 <get_pte>
    if (ptep_store != NULL)
ffffffffc02020d2:	c011                	beqz	s0,ffffffffc02020d6 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02020d4:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02020d6:	c511                	beqz	a0,ffffffffc02020e2 <get_page+0x1e>
ffffffffc02020d8:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02020da:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02020dc:	0017f713          	andi	a4,a5,1
ffffffffc02020e0:	e709                	bnez	a4,ffffffffc02020ea <get_page+0x26>
}
ffffffffc02020e2:	60a2                	ld	ra,8(sp)
ffffffffc02020e4:	6402                	ld	s0,0(sp)
ffffffffc02020e6:	0141                	addi	sp,sp,16
ffffffffc02020e8:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02020ea:	000b3717          	auipc	a4,0xb3
ffffffffc02020ee:	59e73703          	ld	a4,1438(a4) # ffffffffc02b5688 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02020f2:	078a                	slli	a5,a5,0x2
ffffffffc02020f4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020f6:	00e7ff63          	bgeu	a5,a4,ffffffffc0202114 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc02020fa:	000b3517          	auipc	a0,0xb3
ffffffffc02020fe:	59653503          	ld	a0,1430(a0) # ffffffffc02b5690 <pages>
ffffffffc0202102:	60a2                	ld	ra,8(sp)
ffffffffc0202104:	6402                	ld	s0,0(sp)
ffffffffc0202106:	079a                	slli	a5,a5,0x6
ffffffffc0202108:	fe000737          	lui	a4,0xfe000
ffffffffc020210c:	97ba                	add	a5,a5,a4
ffffffffc020210e:	953e                	add	a0,a0,a5
ffffffffc0202110:	0141                	addi	sp,sp,16
ffffffffc0202112:	8082                	ret
ffffffffc0202114:	c8fff0ef          	jal	ffffffffc0201da2 <pa2page.part.0>

ffffffffc0202118 <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202118:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020211a:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020211e:	e486                	sd	ra,72(sp)
ffffffffc0202120:	e0a2                	sd	s0,64(sp)
ffffffffc0202122:	fc26                	sd	s1,56(sp)
ffffffffc0202124:	f84a                	sd	s2,48(sp)
ffffffffc0202126:	f44e                	sd	s3,40(sp)
ffffffffc0202128:	f052                	sd	s4,32(sp)
ffffffffc020212a:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020212c:	03479713          	slli	a4,a5,0x34
ffffffffc0202130:	ef61                	bnez	a4,ffffffffc0202208 <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc0202132:	00200a37          	lui	s4,0x200
ffffffffc0202136:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020213a:	0145b733          	sltu	a4,a1,s4
ffffffffc020213e:	0017b793          	seqz	a5,a5
ffffffffc0202142:	8fd9                	or	a5,a5,a4
ffffffffc0202144:	842e                	mv	s0,a1
ffffffffc0202146:	84b2                	mv	s1,a2
ffffffffc0202148:	e3e5                	bnez	a5,ffffffffc0202228 <unmap_range+0x110>
ffffffffc020214a:	4785                	li	a5,1
ffffffffc020214c:	07fe                	slli	a5,a5,0x1f
ffffffffc020214e:	0785                	addi	a5,a5,1
ffffffffc0202150:	892a                	mv	s2,a0
ffffffffc0202152:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202154:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc0202158:	0cf67863          	bgeu	a2,a5,ffffffffc0202228 <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020215c:	4601                	li	a2,0
ffffffffc020215e:	85a2                	mv	a1,s0
ffffffffc0202160:	854a                	mv	a0,s2
ffffffffc0202162:	d05ff0ef          	jal	ffffffffc0201e66 <get_pte>
ffffffffc0202166:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc0202168:	cd31                	beqz	a0,ffffffffc02021c4 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc020216a:	6118                	ld	a4,0(a0)
ffffffffc020216c:	ef11                	bnez	a4,ffffffffc0202188 <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020216e:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0202170:	c019                	beqz	s0,ffffffffc0202176 <unmap_range+0x5e>
ffffffffc0202172:	fe9465e3          	bltu	s0,s1,ffffffffc020215c <unmap_range+0x44>
}
ffffffffc0202176:	60a6                	ld	ra,72(sp)
ffffffffc0202178:	6406                	ld	s0,64(sp)
ffffffffc020217a:	74e2                	ld	s1,56(sp)
ffffffffc020217c:	7942                	ld	s2,48(sp)
ffffffffc020217e:	79a2                	ld	s3,40(sp)
ffffffffc0202180:	7a02                	ld	s4,32(sp)
ffffffffc0202182:	6ae2                	ld	s5,24(sp)
ffffffffc0202184:	6161                	addi	sp,sp,80
ffffffffc0202186:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202188:	00177693          	andi	a3,a4,1
ffffffffc020218c:	d2ed                	beqz	a3,ffffffffc020216e <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc020218e:	000b3697          	auipc	a3,0xb3
ffffffffc0202192:	4fa6b683          	ld	a3,1274(a3) # ffffffffc02b5688 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202196:	070a                	slli	a4,a4,0x2
ffffffffc0202198:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc020219a:	0ad77763          	bgeu	a4,a3,ffffffffc0202248 <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc020219e:	000b3517          	auipc	a0,0xb3
ffffffffc02021a2:	4f253503          	ld	a0,1266(a0) # ffffffffc02b5690 <pages>
ffffffffc02021a6:	071a                	slli	a4,a4,0x6
ffffffffc02021a8:	fe0006b7          	lui	a3,0xfe000
ffffffffc02021ac:	9736                	add	a4,a4,a3
ffffffffc02021ae:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc02021b0:	4118                	lw	a4,0(a0)
ffffffffc02021b2:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd4a937>
ffffffffc02021b4:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02021b6:	cb19                	beqz	a4,ffffffffc02021cc <unmap_range+0xb4>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02021b8:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02021bc:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02021c0:	944e                	add	s0,s0,s3
ffffffffc02021c2:	b77d                	j	ffffffffc0202170 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021c4:	9452                	add	s0,s0,s4
ffffffffc02021c6:	01547433          	and	s0,s0,s5
            continue;
ffffffffc02021ca:	b75d                	j	ffffffffc0202170 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02021cc:	10002773          	csrr	a4,sstatus
ffffffffc02021d0:	8b09                	andi	a4,a4,2
ffffffffc02021d2:	eb19                	bnez	a4,ffffffffc02021e8 <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc02021d4:	000b3717          	auipc	a4,0xb3
ffffffffc02021d8:	49473703          	ld	a4,1172(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc02021dc:	4585                	li	a1,1
ffffffffc02021de:	e03e                	sd	a5,0(sp)
ffffffffc02021e0:	7318                	ld	a4,32(a4)
ffffffffc02021e2:	9702                	jalr	a4
    if (flag)
ffffffffc02021e4:	6782                	ld	a5,0(sp)
ffffffffc02021e6:	bfc9                	j	ffffffffc02021b8 <unmap_range+0xa0>
        intr_disable();
ffffffffc02021e8:	e43e                	sd	a5,8(sp)
ffffffffc02021ea:	e02a                	sd	a0,0(sp)
ffffffffc02021ec:	f12fe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc02021f0:	000b3717          	auipc	a4,0xb3
ffffffffc02021f4:	47873703          	ld	a4,1144(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc02021f8:	6502                	ld	a0,0(sp)
ffffffffc02021fa:	4585                	li	a1,1
ffffffffc02021fc:	7318                	ld	a4,32(a4)
ffffffffc02021fe:	9702                	jalr	a4
        intr_enable();
ffffffffc0202200:	ef8fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202204:	67a2                	ld	a5,8(sp)
ffffffffc0202206:	bf4d                	j	ffffffffc02021b8 <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202208:	00004697          	auipc	a3,0x4
ffffffffc020220c:	53068693          	addi	a3,a3,1328 # ffffffffc0206738 <etext+0xe90>
ffffffffc0202210:	00004617          	auipc	a2,0x4
ffffffffc0202214:	07860613          	addi	a2,a2,120 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0202218:	12200593          	li	a1,290
ffffffffc020221c:	00004517          	auipc	a0,0x4
ffffffffc0202220:	50c50513          	addi	a0,a0,1292 # ffffffffc0206728 <etext+0xe80>
ffffffffc0202224:	a26fe0ef          	jal	ffffffffc020044a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202228:	00004697          	auipc	a3,0x4
ffffffffc020222c:	54068693          	addi	a3,a3,1344 # ffffffffc0206768 <etext+0xec0>
ffffffffc0202230:	00004617          	auipc	a2,0x4
ffffffffc0202234:	05860613          	addi	a2,a2,88 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0202238:	12300593          	li	a1,291
ffffffffc020223c:	00004517          	auipc	a0,0x4
ffffffffc0202240:	4ec50513          	addi	a0,a0,1260 # ffffffffc0206728 <etext+0xe80>
ffffffffc0202244:	a06fe0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0202248:	b5bff0ef          	jal	ffffffffc0201da2 <pa2page.part.0>

ffffffffc020224c <exit_range>:
{
ffffffffc020224c:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020224e:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202252:	ed06                	sd	ra,152(sp)
ffffffffc0202254:	e922                	sd	s0,144(sp)
ffffffffc0202256:	e526                	sd	s1,136(sp)
ffffffffc0202258:	e14a                	sd	s2,128(sp)
ffffffffc020225a:	fcce                	sd	s3,120(sp)
ffffffffc020225c:	f8d2                	sd	s4,112(sp)
ffffffffc020225e:	f4d6                	sd	s5,104(sp)
ffffffffc0202260:	f0da                	sd	s6,96(sp)
ffffffffc0202262:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202264:	17d2                	slli	a5,a5,0x34
ffffffffc0202266:	22079263          	bnez	a5,ffffffffc020248a <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc020226a:	00200937          	lui	s2,0x200
ffffffffc020226e:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc0202272:	0125b733          	sltu	a4,a1,s2
ffffffffc0202276:	0017b793          	seqz	a5,a5
ffffffffc020227a:	8fd9                	or	a5,a5,a4
ffffffffc020227c:	26079263          	bnez	a5,ffffffffc02024e0 <exit_range+0x294>
ffffffffc0202280:	4785                	li	a5,1
ffffffffc0202282:	07fe                	slli	a5,a5,0x1f
ffffffffc0202284:	0785                	addi	a5,a5,1
ffffffffc0202286:	24f67d63          	bgeu	a2,a5,ffffffffc02024e0 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020228a:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020228e:	ffe007b7          	lui	a5,0xffe00
ffffffffc0202292:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202294:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202296:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc020229a:	000b3a97          	auipc	s5,0xb3
ffffffffc020229e:	3eea8a93          	addi	s5,s5,1006 # ffffffffc02b5688 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02022a2:	400009b7          	lui	s3,0x40000
ffffffffc02022a6:	a809                	j	ffffffffc02022b8 <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc02022a8:	013487b3          	add	a5,s1,s3
ffffffffc02022ac:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02022b0:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02022b2:	c3f1                	beqz	a5,ffffffffc0202376 <exit_range+0x12a>
ffffffffc02022b4:	0cc7f163          	bgeu	a5,a2,ffffffffc0202376 <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02022b8:	01e4d413          	srli	s0,s1,0x1e
ffffffffc02022bc:	1ff47413          	andi	s0,s0,511
ffffffffc02022c0:	040e                	slli	s0,s0,0x3
ffffffffc02022c2:	9452                	add	s0,s0,s4
ffffffffc02022c4:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc02022c8:	0018f793          	andi	a5,a7,1
ffffffffc02022cc:	dff1                	beqz	a5,ffffffffc02022a8 <exit_range+0x5c>
ffffffffc02022ce:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02022d2:	088a                	slli	a7,a7,0x2
ffffffffc02022d4:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc02022d8:	20f8f263          	bgeu	a7,a5,ffffffffc02024dc <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02022dc:	fff802b7          	lui	t0,0xfff80
ffffffffc02022e0:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc02022e4:	000803b7          	lui	t2,0x80
ffffffffc02022e8:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc02022ec:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02022f0:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc02022f2:	1cf77863          	bgeu	a4,a5,ffffffffc02024c2 <exit_range+0x276>
ffffffffc02022f6:	000b3f97          	auipc	t6,0xb3
ffffffffc02022fa:	38af8f93          	addi	t6,t6,906 # ffffffffc02b5680 <va_pa_offset>
ffffffffc02022fe:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc0202302:	4e85                	li	t4,1
ffffffffc0202304:	6b05                	lui	s6,0x1
ffffffffc0202306:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202308:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc020230c:	01585713          	srli	a4,a6,0x15
ffffffffc0202310:	1ff77713          	andi	a4,a4,511
ffffffffc0202314:	070e                	slli	a4,a4,0x3
ffffffffc0202316:	9772                	add	a4,a4,t3
ffffffffc0202318:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc020231a:	0017f693          	andi	a3,a5,1
ffffffffc020231e:	e6bd                	bnez	a3,ffffffffc020238c <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc0202320:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc0202322:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202324:	00080863          	beqz	a6,ffffffffc0202334 <exit_range+0xe8>
ffffffffc0202328:	879a                	mv	a5,t1
ffffffffc020232a:	00667363          	bgeu	a2,t1,ffffffffc0202330 <exit_range+0xe4>
ffffffffc020232e:	87b2                	mv	a5,a2
ffffffffc0202330:	fcf86ee3          	bltu	a6,a5,ffffffffc020230c <exit_range+0xc0>
            if (free_pd0)
ffffffffc0202334:	f60e8ae3          	beqz	t4,ffffffffc02022a8 <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc0202338:	000ab783          	ld	a5,0(s5)
ffffffffc020233c:	1af8f063          	bgeu	a7,a5,ffffffffc02024dc <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202340:	000b3517          	auipc	a0,0xb3
ffffffffc0202344:	35053503          	ld	a0,848(a0) # ffffffffc02b5690 <pages>
ffffffffc0202348:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020234a:	100027f3          	csrr	a5,sstatus
ffffffffc020234e:	8b89                	andi	a5,a5,2
ffffffffc0202350:	10079b63          	bnez	a5,ffffffffc0202466 <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc0202354:	000b3797          	auipc	a5,0xb3
ffffffffc0202358:	3147b783          	ld	a5,788(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc020235c:	4585                	li	a1,1
ffffffffc020235e:	e432                	sd	a2,8(sp)
ffffffffc0202360:	739c                	ld	a5,32(a5)
ffffffffc0202362:	9782                	jalr	a5
ffffffffc0202364:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202366:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc020236a:	013487b3          	add	a5,s1,s3
ffffffffc020236e:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc0202372:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202374:	f3a1                	bnez	a5,ffffffffc02022b4 <exit_range+0x68>
}
ffffffffc0202376:	60ea                	ld	ra,152(sp)
ffffffffc0202378:	644a                	ld	s0,144(sp)
ffffffffc020237a:	64aa                	ld	s1,136(sp)
ffffffffc020237c:	690a                	ld	s2,128(sp)
ffffffffc020237e:	79e6                	ld	s3,120(sp)
ffffffffc0202380:	7a46                	ld	s4,112(sp)
ffffffffc0202382:	7aa6                	ld	s5,104(sp)
ffffffffc0202384:	7b06                	ld	s6,96(sp)
ffffffffc0202386:	6be6                	ld	s7,88(sp)
ffffffffc0202388:	610d                	addi	sp,sp,160
ffffffffc020238a:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc020238c:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202390:	078a                	slli	a5,a5,0x2
ffffffffc0202392:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202394:	14a7f463          	bgeu	a5,a0,ffffffffc02024dc <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202398:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc020239a:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc020239e:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023a2:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc02023a6:	10abf263          	bgeu	s7,a0,ffffffffc02024aa <exit_range+0x25e>
ffffffffc02023aa:	000fb783          	ld	a5,0(t6)
ffffffffc02023ae:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023b0:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc02023b4:	629c                	ld	a5,0(a3)
ffffffffc02023b6:	8b85                	andi	a5,a5,1
ffffffffc02023b8:	f7ad                	bnez	a5,ffffffffc0202322 <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023ba:	06a1                	addi	a3,a3,8
ffffffffc02023bc:	fea69ce3          	bne	a3,a0,ffffffffc02023b4 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc02023c0:	000b3517          	auipc	a0,0xb3
ffffffffc02023c4:	2d053503          	ld	a0,720(a0) # ffffffffc02b5690 <pages>
ffffffffc02023c8:	952e                	add	a0,a0,a1
ffffffffc02023ca:	100027f3          	csrr	a5,sstatus
ffffffffc02023ce:	8b89                	andi	a5,a5,2
ffffffffc02023d0:	e3b9                	bnez	a5,ffffffffc0202416 <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc02023d2:	000b3797          	auipc	a5,0xb3
ffffffffc02023d6:	2967b783          	ld	a5,662(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc02023da:	4585                	li	a1,1
ffffffffc02023dc:	e0b2                	sd	a2,64(sp)
ffffffffc02023de:	739c                	ld	a5,32(a5)
ffffffffc02023e0:	fc1a                	sd	t1,56(sp)
ffffffffc02023e2:	f846                	sd	a7,48(sp)
ffffffffc02023e4:	f47a                	sd	t5,40(sp)
ffffffffc02023e6:	f072                	sd	t3,32(sp)
ffffffffc02023e8:	ec76                	sd	t4,24(sp)
ffffffffc02023ea:	e842                	sd	a6,16(sp)
ffffffffc02023ec:	e43a                	sd	a4,8(sp)
ffffffffc02023ee:	9782                	jalr	a5
    if (flag)
ffffffffc02023f0:	6722                	ld	a4,8(sp)
ffffffffc02023f2:	6842                	ld	a6,16(sp)
ffffffffc02023f4:	6ee2                	ld	t4,24(sp)
ffffffffc02023f6:	7e02                	ld	t3,32(sp)
ffffffffc02023f8:	7f22                	ld	t5,40(sp)
ffffffffc02023fa:	78c2                	ld	a7,48(sp)
ffffffffc02023fc:	7362                	ld	t1,56(sp)
ffffffffc02023fe:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202400:	fff802b7          	lui	t0,0xfff80
ffffffffc0202404:	000803b7          	lui	t2,0x80
ffffffffc0202408:	000b3f97          	auipc	t6,0xb3
ffffffffc020240c:	278f8f93          	addi	t6,t6,632 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0202410:	00073023          	sd	zero,0(a4)
ffffffffc0202414:	b739                	j	ffffffffc0202322 <exit_range+0xd6>
        intr_disable();
ffffffffc0202416:	e4b2                	sd	a2,72(sp)
ffffffffc0202418:	e09a                	sd	t1,64(sp)
ffffffffc020241a:	fc46                	sd	a7,56(sp)
ffffffffc020241c:	f47a                	sd	t5,40(sp)
ffffffffc020241e:	f072                	sd	t3,32(sp)
ffffffffc0202420:	ec76                	sd	t4,24(sp)
ffffffffc0202422:	e842                	sd	a6,16(sp)
ffffffffc0202424:	e43a                	sd	a4,8(sp)
ffffffffc0202426:	f82a                	sd	a0,48(sp)
ffffffffc0202428:	cd6fe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020242c:	000b3797          	auipc	a5,0xb3
ffffffffc0202430:	23c7b783          	ld	a5,572(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202434:	7542                	ld	a0,48(sp)
ffffffffc0202436:	4585                	li	a1,1
ffffffffc0202438:	739c                	ld	a5,32(a5)
ffffffffc020243a:	9782                	jalr	a5
        intr_enable();
ffffffffc020243c:	cbcfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202440:	6722                	ld	a4,8(sp)
ffffffffc0202442:	6626                	ld	a2,72(sp)
ffffffffc0202444:	6306                	ld	t1,64(sp)
ffffffffc0202446:	78e2                	ld	a7,56(sp)
ffffffffc0202448:	7f22                	ld	t5,40(sp)
ffffffffc020244a:	7e02                	ld	t3,32(sp)
ffffffffc020244c:	6ee2                	ld	t4,24(sp)
ffffffffc020244e:	6842                	ld	a6,16(sp)
ffffffffc0202450:	000b3f97          	auipc	t6,0xb3
ffffffffc0202454:	230f8f93          	addi	t6,t6,560 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0202458:	000803b7          	lui	t2,0x80
ffffffffc020245c:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202460:	00073023          	sd	zero,0(a4)
ffffffffc0202464:	bd7d                	j	ffffffffc0202322 <exit_range+0xd6>
        intr_disable();
ffffffffc0202466:	e832                	sd	a2,16(sp)
ffffffffc0202468:	e42a                	sd	a0,8(sp)
ffffffffc020246a:	c94fe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020246e:	000b3797          	auipc	a5,0xb3
ffffffffc0202472:	1fa7b783          	ld	a5,506(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202476:	6522                	ld	a0,8(sp)
ffffffffc0202478:	4585                	li	a1,1
ffffffffc020247a:	739c                	ld	a5,32(a5)
ffffffffc020247c:	9782                	jalr	a5
        intr_enable();
ffffffffc020247e:	c7afe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202482:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202484:	00043023          	sd	zero,0(s0)
ffffffffc0202488:	b5cd                	j	ffffffffc020236a <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020248a:	00004697          	auipc	a3,0x4
ffffffffc020248e:	2ae68693          	addi	a3,a3,686 # ffffffffc0206738 <etext+0xe90>
ffffffffc0202492:	00004617          	auipc	a2,0x4
ffffffffc0202496:	df660613          	addi	a2,a2,-522 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020249a:	13700593          	li	a1,311
ffffffffc020249e:	00004517          	auipc	a0,0x4
ffffffffc02024a2:	28a50513          	addi	a0,a0,650 # ffffffffc0206728 <etext+0xe80>
ffffffffc02024a6:	fa5fd0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc02024aa:	00004617          	auipc	a2,0x4
ffffffffc02024ae:	18e60613          	addi	a2,a2,398 # ffffffffc0206638 <etext+0xd90>
ffffffffc02024b2:	07100593          	li	a1,113
ffffffffc02024b6:	00004517          	auipc	a0,0x4
ffffffffc02024ba:	1aa50513          	addi	a0,a0,426 # ffffffffc0206660 <etext+0xdb8>
ffffffffc02024be:	f8dfd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc02024c2:	86f2                	mv	a3,t3
ffffffffc02024c4:	00004617          	auipc	a2,0x4
ffffffffc02024c8:	17460613          	addi	a2,a2,372 # ffffffffc0206638 <etext+0xd90>
ffffffffc02024cc:	07100593          	li	a1,113
ffffffffc02024d0:	00004517          	auipc	a0,0x4
ffffffffc02024d4:	19050513          	addi	a0,a0,400 # ffffffffc0206660 <etext+0xdb8>
ffffffffc02024d8:	f73fd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc02024dc:	8c7ff0ef          	jal	ffffffffc0201da2 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02024e0:	00004697          	auipc	a3,0x4
ffffffffc02024e4:	28868693          	addi	a3,a3,648 # ffffffffc0206768 <etext+0xec0>
ffffffffc02024e8:	00004617          	auipc	a2,0x4
ffffffffc02024ec:	da060613          	addi	a2,a2,-608 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02024f0:	13800593          	li	a1,312
ffffffffc02024f4:	00004517          	auipc	a0,0x4
ffffffffc02024f8:	23450513          	addi	a0,a0,564 # ffffffffc0206728 <etext+0xe80>
ffffffffc02024fc:	f4ffd0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0202500 <copy_range>:
{
ffffffffc0202500:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202502:	00d667b3          	or	a5,a2,a3
{
ffffffffc0202506:	f486                	sd	ra,104(sp)
ffffffffc0202508:	f0a2                	sd	s0,96(sp)
ffffffffc020250a:	eca6                	sd	s1,88(sp)
ffffffffc020250c:	e8ca                	sd	s2,80(sp)
ffffffffc020250e:	e4ce                	sd	s3,72(sp)
ffffffffc0202510:	e0d2                	sd	s4,64(sp)
ffffffffc0202512:	fc56                	sd	s5,56(sp)
ffffffffc0202514:	f85a                	sd	s6,48(sp)
ffffffffc0202516:	f45e                	sd	s7,40(sp)
ffffffffc0202518:	f062                	sd	s8,32(sp)
ffffffffc020251a:	ec66                	sd	s9,24(sp)
ffffffffc020251c:	e86a                	sd	s10,16(sp)
ffffffffc020251e:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202520:	03479713          	slli	a4,a5,0x34
ffffffffc0202524:	18071163          	bnez	a4,ffffffffc02026a6 <copy_range+0x1a6>
    assert(USER_ACCESS(start, end));
ffffffffc0202528:	00200cb7          	lui	s9,0x200
ffffffffc020252c:	00d637b3          	sltu	a5,a2,a3
ffffffffc0202530:	01963733          	sltu	a4,a2,s9
ffffffffc0202534:	0017b793          	seqz	a5,a5
ffffffffc0202538:	8fd9                	or	a5,a5,a4
ffffffffc020253a:	8432                	mv	s0,a2
ffffffffc020253c:	84b6                	mv	s1,a3
ffffffffc020253e:	14079463          	bnez	a5,ffffffffc0202686 <copy_range+0x186>
ffffffffc0202542:	4785                	li	a5,1
ffffffffc0202544:	07fe                	slli	a5,a5,0x1f
ffffffffc0202546:	0785                	addi	a5,a5,1
ffffffffc0202548:	12f6ff63          	bgeu	a3,a5,ffffffffc0202686 <copy_range+0x186>
ffffffffc020254c:	8aaa                	mv	s5,a0
ffffffffc020254e:	892e                	mv	s2,a1
ffffffffc0202550:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage)
ffffffffc0202552:	000b3c17          	auipc	s8,0xb3
ffffffffc0202556:	136c0c13          	addi	s8,s8,310 # ffffffffc02b5688 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020255a:	000b3b97          	auipc	s7,0xb3
ffffffffc020255e:	136b8b93          	addi	s7,s7,310 # ffffffffc02b5690 <pages>
ffffffffc0202562:	fff80b37          	lui	s6,0xfff80
        page = pmm_manager->alloc_pages(n);
ffffffffc0202566:	000b3a17          	auipc	s4,0xb3
ffffffffc020256a:	102a0a13          	addi	s4,s4,258 # ffffffffc02b5668 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020256e:	4601                	li	a2,0
ffffffffc0202570:	85a2                	mv	a1,s0
ffffffffc0202572:	854a                	mv	a0,s2
ffffffffc0202574:	8f3ff0ef          	jal	ffffffffc0201e66 <get_pte>
ffffffffc0202578:	8d2a                	mv	s10,a0
        if (ptep == NULL)
ffffffffc020257a:	cd41                	beqz	a0,ffffffffc0202612 <copy_range+0x112>
        if (*ptep & PTE_V)
ffffffffc020257c:	611c                	ld	a5,0(a0)
ffffffffc020257e:	8b85                	andi	a5,a5,1
ffffffffc0202580:	e78d                	bnez	a5,ffffffffc02025aa <copy_range+0xaa>
        start += PGSIZE;
ffffffffc0202582:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0202584:	c019                	beqz	s0,ffffffffc020258a <copy_range+0x8a>
ffffffffc0202586:	fe9464e3          	bltu	s0,s1,ffffffffc020256e <copy_range+0x6e>
    return 0;
ffffffffc020258a:	4501                	li	a0,0
}
ffffffffc020258c:	70a6                	ld	ra,104(sp)
ffffffffc020258e:	7406                	ld	s0,96(sp)
ffffffffc0202590:	64e6                	ld	s1,88(sp)
ffffffffc0202592:	6946                	ld	s2,80(sp)
ffffffffc0202594:	69a6                	ld	s3,72(sp)
ffffffffc0202596:	6a06                	ld	s4,64(sp)
ffffffffc0202598:	7ae2                	ld	s5,56(sp)
ffffffffc020259a:	7b42                	ld	s6,48(sp)
ffffffffc020259c:	7ba2                	ld	s7,40(sp)
ffffffffc020259e:	7c02                	ld	s8,32(sp)
ffffffffc02025a0:	6ce2                	ld	s9,24(sp)
ffffffffc02025a2:	6d42                	ld	s10,16(sp)
ffffffffc02025a4:	6da2                	ld	s11,8(sp)
ffffffffc02025a6:	6165                	addi	sp,sp,112
ffffffffc02025a8:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02025aa:	4605                	li	a2,1
ffffffffc02025ac:	85a2                	mv	a1,s0
ffffffffc02025ae:	8556                	mv	a0,s5
ffffffffc02025b0:	8b7ff0ef          	jal	ffffffffc0201e66 <get_pte>
ffffffffc02025b4:	cd3d                	beqz	a0,ffffffffc0202632 <copy_range+0x132>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02025b6:	000d3783          	ld	a5,0(s10)
    if (!(pte & PTE_V))
ffffffffc02025ba:	0017f713          	andi	a4,a5,1
ffffffffc02025be:	cf25                	beqz	a4,ffffffffc0202636 <copy_range+0x136>
    if (PPN(pa) >= npage)
ffffffffc02025c0:	000c3703          	ld	a4,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02025c4:	078a                	slli	a5,a5,0x2
ffffffffc02025c6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025c8:	0ae7f363          	bgeu	a5,a4,ffffffffc020266e <copy_range+0x16e>
    return &pages[PPN(pa) - nbase];
ffffffffc02025cc:	000bbd83          	ld	s11,0(s7)
ffffffffc02025d0:	97da                	add	a5,a5,s6
ffffffffc02025d2:	079a                	slli	a5,a5,0x6
ffffffffc02025d4:	9dbe                	add	s11,s11,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025d6:	100027f3          	csrr	a5,sstatus
ffffffffc02025da:	8b89                	andi	a5,a5,2
ffffffffc02025dc:	e3a1                	bnez	a5,ffffffffc020261c <copy_range+0x11c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02025de:	000a3783          	ld	a5,0(s4)
ffffffffc02025e2:	4505                	li	a0,1
ffffffffc02025e4:	6f9c                	ld	a5,24(a5)
ffffffffc02025e6:	9782                	jalr	a5
ffffffffc02025e8:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc02025ea:	060d8263          	beqz	s11,ffffffffc020264e <copy_range+0x14e>
            assert(npage != NULL);
ffffffffc02025ee:	f80d1ae3          	bnez	s10,ffffffffc0202582 <copy_range+0x82>
ffffffffc02025f2:	00004697          	auipc	a3,0x4
ffffffffc02025f6:	1c668693          	addi	a3,a3,454 # ffffffffc02067b8 <etext+0xf10>
ffffffffc02025fa:	00004617          	auipc	a2,0x4
ffffffffc02025fe:	c8e60613          	addi	a2,a2,-882 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0202602:	19700593          	li	a1,407
ffffffffc0202606:	00004517          	auipc	a0,0x4
ffffffffc020260a:	12250513          	addi	a0,a0,290 # ffffffffc0206728 <etext+0xe80>
ffffffffc020260e:	e3dfd0ef          	jal	ffffffffc020044a <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202612:	9466                	add	s0,s0,s9
ffffffffc0202614:	ffe007b7          	lui	a5,0xffe00
ffffffffc0202618:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc020261a:	b7ad                	j	ffffffffc0202584 <copy_range+0x84>
        intr_disable();
ffffffffc020261c:	ae2fe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202620:	000a3783          	ld	a5,0(s4)
ffffffffc0202624:	4505                	li	a0,1
ffffffffc0202626:	6f9c                	ld	a5,24(a5)
ffffffffc0202628:	9782                	jalr	a5
ffffffffc020262a:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc020262c:	accfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202630:	bf6d                	j	ffffffffc02025ea <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc0202632:	5571                	li	a0,-4
ffffffffc0202634:	bfa1                	j	ffffffffc020258c <copy_range+0x8c>
        panic("pte2page called with invalid pte");
ffffffffc0202636:	00004617          	auipc	a2,0x4
ffffffffc020263a:	14a60613          	addi	a2,a2,330 # ffffffffc0206780 <etext+0xed8>
ffffffffc020263e:	07f00593          	li	a1,127
ffffffffc0202642:	00004517          	auipc	a0,0x4
ffffffffc0202646:	01e50513          	addi	a0,a0,30 # ffffffffc0206660 <etext+0xdb8>
ffffffffc020264a:	e01fd0ef          	jal	ffffffffc020044a <__panic>
            assert(page != NULL);
ffffffffc020264e:	00004697          	auipc	a3,0x4
ffffffffc0202652:	15a68693          	addi	a3,a3,346 # ffffffffc02067a8 <etext+0xf00>
ffffffffc0202656:	00004617          	auipc	a2,0x4
ffffffffc020265a:	c3260613          	addi	a2,a2,-974 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020265e:	19600593          	li	a1,406
ffffffffc0202662:	00004517          	auipc	a0,0x4
ffffffffc0202666:	0c650513          	addi	a0,a0,198 # ffffffffc0206728 <etext+0xe80>
ffffffffc020266a:	de1fd0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020266e:	00004617          	auipc	a2,0x4
ffffffffc0202672:	09a60613          	addi	a2,a2,154 # ffffffffc0206708 <etext+0xe60>
ffffffffc0202676:	06900593          	li	a1,105
ffffffffc020267a:	00004517          	auipc	a0,0x4
ffffffffc020267e:	fe650513          	addi	a0,a0,-26 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0202682:	dc9fd0ef          	jal	ffffffffc020044a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202686:	00004697          	auipc	a3,0x4
ffffffffc020268a:	0e268693          	addi	a3,a3,226 # ffffffffc0206768 <etext+0xec0>
ffffffffc020268e:	00004617          	auipc	a2,0x4
ffffffffc0202692:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0202696:	17e00593          	li	a1,382
ffffffffc020269a:	00004517          	auipc	a0,0x4
ffffffffc020269e:	08e50513          	addi	a0,a0,142 # ffffffffc0206728 <etext+0xe80>
ffffffffc02026a2:	da9fd0ef          	jal	ffffffffc020044a <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02026a6:	00004697          	auipc	a3,0x4
ffffffffc02026aa:	09268693          	addi	a3,a3,146 # ffffffffc0206738 <etext+0xe90>
ffffffffc02026ae:	00004617          	auipc	a2,0x4
ffffffffc02026b2:	bda60613          	addi	a2,a2,-1062 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02026b6:	17d00593          	li	a1,381
ffffffffc02026ba:	00004517          	auipc	a0,0x4
ffffffffc02026be:	06e50513          	addi	a0,a0,110 # ffffffffc0206728 <etext+0xe80>
ffffffffc02026c2:	d89fd0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02026c6 <page_remove>:
{
ffffffffc02026c6:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02026c8:	4601                	li	a2,0
{
ffffffffc02026ca:	e822                	sd	s0,16(sp)
ffffffffc02026cc:	ec06                	sd	ra,24(sp)
ffffffffc02026ce:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02026d0:	f96ff0ef          	jal	ffffffffc0201e66 <get_pte>
    if (ptep != NULL)
ffffffffc02026d4:	c511                	beqz	a0,ffffffffc02026e0 <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc02026d6:	6118                	ld	a4,0(a0)
ffffffffc02026d8:	87aa                	mv	a5,a0
ffffffffc02026da:	00177693          	andi	a3,a4,1
ffffffffc02026de:	e689                	bnez	a3,ffffffffc02026e8 <page_remove+0x22>
}
ffffffffc02026e0:	60e2                	ld	ra,24(sp)
ffffffffc02026e2:	6442                	ld	s0,16(sp)
ffffffffc02026e4:	6105                	addi	sp,sp,32
ffffffffc02026e6:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02026e8:	000b3697          	auipc	a3,0xb3
ffffffffc02026ec:	fa06b683          	ld	a3,-96(a3) # ffffffffc02b5688 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02026f0:	070a                	slli	a4,a4,0x2
ffffffffc02026f2:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02026f4:	06d77563          	bgeu	a4,a3,ffffffffc020275e <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02026f8:	000b3517          	auipc	a0,0xb3
ffffffffc02026fc:	f9853503          	ld	a0,-104(a0) # ffffffffc02b5690 <pages>
ffffffffc0202700:	071a                	slli	a4,a4,0x6
ffffffffc0202702:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202706:	9736                	add	a4,a4,a3
ffffffffc0202708:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc020270a:	4118                	lw	a4,0(a0)
ffffffffc020270c:	377d                	addiw	a4,a4,-1
ffffffffc020270e:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202710:	cb09                	beqz	a4,ffffffffc0202722 <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202712:	0007b023          	sd	zero,0(a5) # ffffffffffe00000 <end+0x3fb4a938>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202716:	12040073          	sfence.vma	s0
}
ffffffffc020271a:	60e2                	ld	ra,24(sp)
ffffffffc020271c:	6442                	ld	s0,16(sp)
ffffffffc020271e:	6105                	addi	sp,sp,32
ffffffffc0202720:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202722:	10002773          	csrr	a4,sstatus
ffffffffc0202726:	8b09                	andi	a4,a4,2
ffffffffc0202728:	eb19                	bnez	a4,ffffffffc020273e <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc020272a:	000b3717          	auipc	a4,0xb3
ffffffffc020272e:	f3e73703          	ld	a4,-194(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202732:	4585                	li	a1,1
ffffffffc0202734:	e03e                	sd	a5,0(sp)
ffffffffc0202736:	7318                	ld	a4,32(a4)
ffffffffc0202738:	9702                	jalr	a4
    if (flag)
ffffffffc020273a:	6782                	ld	a5,0(sp)
ffffffffc020273c:	bfd9                	j	ffffffffc0202712 <page_remove+0x4c>
        intr_disable();
ffffffffc020273e:	e43e                	sd	a5,8(sp)
ffffffffc0202740:	e02a                	sd	a0,0(sp)
ffffffffc0202742:	9bcfe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202746:	000b3717          	auipc	a4,0xb3
ffffffffc020274a:	f2273703          	ld	a4,-222(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc020274e:	6502                	ld	a0,0(sp)
ffffffffc0202750:	4585                	li	a1,1
ffffffffc0202752:	7318                	ld	a4,32(a4)
ffffffffc0202754:	9702                	jalr	a4
        intr_enable();
ffffffffc0202756:	9a2fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020275a:	67a2                	ld	a5,8(sp)
ffffffffc020275c:	bf5d                	j	ffffffffc0202712 <page_remove+0x4c>
ffffffffc020275e:	e44ff0ef          	jal	ffffffffc0201da2 <pa2page.part.0>

ffffffffc0202762 <page_insert>:
{
ffffffffc0202762:	7139                	addi	sp,sp,-64
ffffffffc0202764:	f426                	sd	s1,40(sp)
ffffffffc0202766:	84b2                	mv	s1,a2
ffffffffc0202768:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020276a:	4605                	li	a2,1
{
ffffffffc020276c:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020276e:	85a6                	mv	a1,s1
{
ffffffffc0202770:	fc06                	sd	ra,56(sp)
ffffffffc0202772:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202774:	ef2ff0ef          	jal	ffffffffc0201e66 <get_pte>
    if (ptep == NULL)
ffffffffc0202778:	cd61                	beqz	a0,ffffffffc0202850 <page_insert+0xee>
    page->ref += 1;
ffffffffc020277a:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc020277c:	611c                	ld	a5,0(a0)
ffffffffc020277e:	66a2                	ld	a3,8(sp)
ffffffffc0202780:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7f27>
ffffffffc0202784:	c010                	sw	a2,0(s0)
ffffffffc0202786:	0017f613          	andi	a2,a5,1
ffffffffc020278a:	872a                	mv	a4,a0
ffffffffc020278c:	e61d                	bnez	a2,ffffffffc02027ba <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc020278e:	000b3617          	auipc	a2,0xb3
ffffffffc0202792:	f0263603          	ld	a2,-254(a2) # ffffffffc02b5690 <pages>
    return page - pages + nbase;
ffffffffc0202796:	8c11                	sub	s0,s0,a2
ffffffffc0202798:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020279a:	200007b7          	lui	a5,0x20000
ffffffffc020279e:	042a                	slli	s0,s0,0xa
ffffffffc02027a0:	943e                	add	s0,s0,a5
ffffffffc02027a2:	8ec1                	or	a3,a3,s0
ffffffffc02027a4:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02027a8:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027aa:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02027ae:	4501                	li	a0,0
}
ffffffffc02027b0:	70e2                	ld	ra,56(sp)
ffffffffc02027b2:	7442                	ld	s0,48(sp)
ffffffffc02027b4:	74a2                	ld	s1,40(sp)
ffffffffc02027b6:	6121                	addi	sp,sp,64
ffffffffc02027b8:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02027ba:	000b3617          	auipc	a2,0xb3
ffffffffc02027be:	ece63603          	ld	a2,-306(a2) # ffffffffc02b5688 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02027c2:	078a                	slli	a5,a5,0x2
ffffffffc02027c4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02027c6:	08c7f763          	bgeu	a5,a2,ffffffffc0202854 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02027ca:	000b3617          	auipc	a2,0xb3
ffffffffc02027ce:	ec663603          	ld	a2,-314(a2) # ffffffffc02b5690 <pages>
ffffffffc02027d2:	fe000537          	lui	a0,0xfe000
ffffffffc02027d6:	079a                	slli	a5,a5,0x6
ffffffffc02027d8:	97aa                	add	a5,a5,a0
ffffffffc02027da:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02027de:	00a40963          	beq	s0,a0,ffffffffc02027f0 <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02027e2:	411c                	lw	a5,0(a0)
ffffffffc02027e4:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_matrix_out_size+0x1fff4abf>
ffffffffc02027e6:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc02027e8:	c791                	beqz	a5,ffffffffc02027f4 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027ea:	12048073          	sfence.vma	s1
}
ffffffffc02027ee:	b765                	j	ffffffffc0202796 <page_insert+0x34>
ffffffffc02027f0:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc02027f2:	b755                	j	ffffffffc0202796 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02027f4:	100027f3          	csrr	a5,sstatus
ffffffffc02027f8:	8b89                	andi	a5,a5,2
ffffffffc02027fa:	e39d                	bnez	a5,ffffffffc0202820 <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc02027fc:	000b3797          	auipc	a5,0xb3
ffffffffc0202800:	e6c7b783          	ld	a5,-404(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202804:	4585                	li	a1,1
ffffffffc0202806:	e83a                	sd	a4,16(sp)
ffffffffc0202808:	739c                	ld	a5,32(a5)
ffffffffc020280a:	e436                	sd	a3,8(sp)
ffffffffc020280c:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020280e:	000b3617          	auipc	a2,0xb3
ffffffffc0202812:	e8263603          	ld	a2,-382(a2) # ffffffffc02b5690 <pages>
ffffffffc0202816:	66a2                	ld	a3,8(sp)
ffffffffc0202818:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020281a:	12048073          	sfence.vma	s1
ffffffffc020281e:	bfa5                	j	ffffffffc0202796 <page_insert+0x34>
        intr_disable();
ffffffffc0202820:	ec3a                	sd	a4,24(sp)
ffffffffc0202822:	e836                	sd	a3,16(sp)
ffffffffc0202824:	e42a                	sd	a0,8(sp)
ffffffffc0202826:	8d8fe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020282a:	000b3797          	auipc	a5,0xb3
ffffffffc020282e:	e3e7b783          	ld	a5,-450(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202832:	6522                	ld	a0,8(sp)
ffffffffc0202834:	4585                	li	a1,1
ffffffffc0202836:	739c                	ld	a5,32(a5)
ffffffffc0202838:	9782                	jalr	a5
        intr_enable();
ffffffffc020283a:	8befe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020283e:	000b3617          	auipc	a2,0xb3
ffffffffc0202842:	e5263603          	ld	a2,-430(a2) # ffffffffc02b5690 <pages>
ffffffffc0202846:	6762                	ld	a4,24(sp)
ffffffffc0202848:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020284a:	12048073          	sfence.vma	s1
ffffffffc020284e:	b7a1                	j	ffffffffc0202796 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc0202850:	5571                	li	a0,-4
ffffffffc0202852:	bfb9                	j	ffffffffc02027b0 <page_insert+0x4e>
ffffffffc0202854:	d4eff0ef          	jal	ffffffffc0201da2 <pa2page.part.0>

ffffffffc0202858 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202858:	00005797          	auipc	a5,0x5
ffffffffc020285c:	e6878793          	addi	a5,a5,-408 # ffffffffc02076c0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202860:	638c                	ld	a1,0(a5)
{
ffffffffc0202862:	7159                	addi	sp,sp,-112
ffffffffc0202864:	f486                	sd	ra,104(sp)
ffffffffc0202866:	e8ca                	sd	s2,80(sp)
ffffffffc0202868:	e4ce                	sd	s3,72(sp)
ffffffffc020286a:	f85a                	sd	s6,48(sp)
ffffffffc020286c:	f0a2                	sd	s0,96(sp)
ffffffffc020286e:	eca6                	sd	s1,88(sp)
ffffffffc0202870:	e0d2                	sd	s4,64(sp)
ffffffffc0202872:	fc56                	sd	s5,56(sp)
ffffffffc0202874:	f45e                	sd	s7,40(sp)
ffffffffc0202876:	f062                	sd	s8,32(sp)
ffffffffc0202878:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020287a:	000b3b17          	auipc	s6,0xb3
ffffffffc020287e:	deeb0b13          	addi	s6,s6,-530 # ffffffffc02b5668 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202882:	00004517          	auipc	a0,0x4
ffffffffc0202886:	f4650513          	addi	a0,a0,-186 # ffffffffc02067c8 <etext+0xf20>
    pmm_manager = &default_pmm_manager;
ffffffffc020288a:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020288e:	90bfd0ef          	jal	ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc0202892:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202896:	000b3997          	auipc	s3,0xb3
ffffffffc020289a:	dea98993          	addi	s3,s3,-534 # ffffffffc02b5680 <va_pa_offset>
    pmm_manager->init();
ffffffffc020289e:	679c                	ld	a5,8(a5)
ffffffffc02028a0:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02028a2:	57f5                	li	a5,-3
ffffffffc02028a4:	07fa                	slli	a5,a5,0x1e
ffffffffc02028a6:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02028aa:	83afe0ef          	jal	ffffffffc02008e4 <get_memory_base>
ffffffffc02028ae:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02028b0:	83efe0ef          	jal	ffffffffc02008ee <get_memory_size>
    if (mem_size == 0)
ffffffffc02028b4:	70050e63          	beqz	a0,ffffffffc0202fd0 <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02028b8:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02028ba:	00004517          	auipc	a0,0x4
ffffffffc02028be:	f4650513          	addi	a0,a0,-186 # ffffffffc0206800 <etext+0xf58>
ffffffffc02028c2:	8d7fd0ef          	jal	ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02028c6:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02028ca:	864a                	mv	a2,s2
ffffffffc02028cc:	85a6                	mv	a1,s1
ffffffffc02028ce:	fff40693          	addi	a3,s0,-1
ffffffffc02028d2:	00004517          	auipc	a0,0x4
ffffffffc02028d6:	f4650513          	addi	a0,a0,-186 # ffffffffc0206818 <etext+0xf70>
ffffffffc02028da:	8bffd0ef          	jal	ffffffffc0200198 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02028de:	c80007b7          	lui	a5,0xc8000
ffffffffc02028e2:	8522                	mv	a0,s0
ffffffffc02028e4:	5287ed63          	bltu	a5,s0,ffffffffc0202e1e <pmm_init+0x5c6>
ffffffffc02028e8:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02028ea:	000b4617          	auipc	a2,0xb4
ffffffffc02028ee:	ddd60613          	addi	a2,a2,-547 # ffffffffc02b66c7 <end+0xfff>
ffffffffc02028f2:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc02028f4:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02028f6:	000b3b97          	auipc	s7,0xb3
ffffffffc02028fa:	d9ab8b93          	addi	s7,s7,-614 # ffffffffc02b5690 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02028fe:	000b3497          	auipc	s1,0xb3
ffffffffc0202902:	d8a48493          	addi	s1,s1,-630 # ffffffffc02b5688 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202906:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc020290a:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020290c:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202910:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202912:	02f50763          	beq	a0,a5,ffffffffc0202940 <pmm_init+0xe8>
ffffffffc0202916:	4701                	li	a4,0
ffffffffc0202918:	4585                	li	a1,1
ffffffffc020291a:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020291e:	00671793          	slli	a5,a4,0x6
ffffffffc0202922:	97b2                	add	a5,a5,a2
ffffffffc0202924:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_matrix_out_size+0x74ac8>
ffffffffc0202926:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020292a:	6088                	ld	a0,0(s1)
ffffffffc020292c:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020292e:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202932:	00d507b3          	add	a5,a0,a3
ffffffffc0202936:	fef764e3          	bltu	a4,a5,ffffffffc020291e <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020293a:	079a                	slli	a5,a5,0x6
ffffffffc020293c:	00f606b3          	add	a3,a2,a5
ffffffffc0202940:	c02007b7          	lui	a5,0xc0200
ffffffffc0202944:	16f6eee3          	bltu	a3,a5,ffffffffc02032c0 <pmm_init+0xa68>
ffffffffc0202948:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020294c:	77fd                	lui	a5,0xfffff
ffffffffc020294e:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202950:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202952:	4e86ed63          	bltu	a3,s0,ffffffffc0202e4c <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202956:	00004517          	auipc	a0,0x4
ffffffffc020295a:	eea50513          	addi	a0,a0,-278 # ffffffffc0206840 <etext+0xf98>
ffffffffc020295e:	83bfd0ef          	jal	ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202962:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202966:	000b3917          	auipc	s2,0xb3
ffffffffc020296a:	d1290913          	addi	s2,s2,-750 # ffffffffc02b5678 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020296e:	7b9c                	ld	a5,48(a5)
ffffffffc0202970:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202972:	00004517          	auipc	a0,0x4
ffffffffc0202976:	ee650513          	addi	a0,a0,-282 # ffffffffc0206858 <etext+0xfb0>
ffffffffc020297a:	81ffd0ef          	jal	ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020297e:	00008697          	auipc	a3,0x8
ffffffffc0202982:	68268693          	addi	a3,a3,1666 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202986:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020298a:	c02007b7          	lui	a5,0xc0200
ffffffffc020298e:	2af6eee3          	bltu	a3,a5,ffffffffc020344a <pmm_init+0xbf2>
ffffffffc0202992:	0009b783          	ld	a5,0(s3)
ffffffffc0202996:	8e9d                	sub	a3,a3,a5
ffffffffc0202998:	000b3797          	auipc	a5,0xb3
ffffffffc020299c:	ccd7bc23          	sd	a3,-808(a5) # ffffffffc02b5670 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02029a0:	100027f3          	csrr	a5,sstatus
ffffffffc02029a4:	8b89                	andi	a5,a5,2
ffffffffc02029a6:	48079963          	bnez	a5,ffffffffc0202e38 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02029aa:	000b3783          	ld	a5,0(s6)
ffffffffc02029ae:	779c                	ld	a5,40(a5)
ffffffffc02029b0:	9782                	jalr	a5
ffffffffc02029b2:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02029b4:	6098                	ld	a4,0(s1)
ffffffffc02029b6:	c80007b7          	lui	a5,0xc8000
ffffffffc02029ba:	83b1                	srli	a5,a5,0xc
ffffffffc02029bc:	66e7e663          	bltu	a5,a4,ffffffffc0203028 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02029c0:	00093503          	ld	a0,0(s2)
ffffffffc02029c4:	64050263          	beqz	a0,ffffffffc0203008 <pmm_init+0x7b0>
ffffffffc02029c8:	03451793          	slli	a5,a0,0x34
ffffffffc02029cc:	62079e63          	bnez	a5,ffffffffc0203008 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02029d0:	4601                	li	a2,0
ffffffffc02029d2:	4581                	li	a1,0
ffffffffc02029d4:	ef0ff0ef          	jal	ffffffffc02020c4 <get_page>
ffffffffc02029d8:	240519e3          	bnez	a0,ffffffffc020342a <pmm_init+0xbd2>
ffffffffc02029dc:	100027f3          	csrr	a5,sstatus
ffffffffc02029e0:	8b89                	andi	a5,a5,2
ffffffffc02029e2:	44079063          	bnez	a5,ffffffffc0202e22 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029e6:	000b3783          	ld	a5,0(s6)
ffffffffc02029ea:	4505                	li	a0,1
ffffffffc02029ec:	6f9c                	ld	a5,24(a5)
ffffffffc02029ee:	9782                	jalr	a5
ffffffffc02029f0:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02029f2:	00093503          	ld	a0,0(s2)
ffffffffc02029f6:	4681                	li	a3,0
ffffffffc02029f8:	4601                	li	a2,0
ffffffffc02029fa:	85d2                	mv	a1,s4
ffffffffc02029fc:	d67ff0ef          	jal	ffffffffc0202762 <page_insert>
ffffffffc0202a00:	280511e3          	bnez	a0,ffffffffc0203482 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202a04:	00093503          	ld	a0,0(s2)
ffffffffc0202a08:	4601                	li	a2,0
ffffffffc0202a0a:	4581                	li	a1,0
ffffffffc0202a0c:	c5aff0ef          	jal	ffffffffc0201e66 <get_pte>
ffffffffc0202a10:	240509e3          	beqz	a0,ffffffffc0203462 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a14:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a16:	0017f713          	andi	a4,a5,1
ffffffffc0202a1a:	58070f63          	beqz	a4,ffffffffc0202fb8 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202a1e:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a20:	078a                	slli	a5,a5,0x2
ffffffffc0202a22:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a24:	58e7f863          	bgeu	a5,a4,ffffffffc0202fb4 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a28:	000bb683          	ld	a3,0(s7)
ffffffffc0202a2c:	079a                	slli	a5,a5,0x6
ffffffffc0202a2e:	fe000637          	lui	a2,0xfe000
ffffffffc0202a32:	97b2                	add	a5,a5,a2
ffffffffc0202a34:	97b6                	add	a5,a5,a3
ffffffffc0202a36:	14fa1ae3          	bne	s4,a5,ffffffffc020338a <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202a3a:	000a2683          	lw	a3,0(s4)
ffffffffc0202a3e:	4785                	li	a5,1
ffffffffc0202a40:	12f695e3          	bne	a3,a5,ffffffffc020336a <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202a44:	00093503          	ld	a0,0(s2)
ffffffffc0202a48:	77fd                	lui	a5,0xfffff
ffffffffc0202a4a:	6114                	ld	a3,0(a0)
ffffffffc0202a4c:	068a                	slli	a3,a3,0x2
ffffffffc0202a4e:	8efd                	and	a3,a3,a5
ffffffffc0202a50:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202a54:	0ee67fe3          	bgeu	a2,a4,ffffffffc0203352 <pmm_init+0xafa>
ffffffffc0202a58:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a5c:	96e2                	add	a3,a3,s8
ffffffffc0202a5e:	0006ba83          	ld	s5,0(a3)
ffffffffc0202a62:	0a8a                	slli	s5,s5,0x2
ffffffffc0202a64:	00fafab3          	and	s5,s5,a5
ffffffffc0202a68:	00cad793          	srli	a5,s5,0xc
ffffffffc0202a6c:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0203338 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a70:	4601                	li	a2,0
ffffffffc0202a72:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a74:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a76:	bf0ff0ef          	jal	ffffffffc0201e66 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a7a:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a7c:	05851ee3          	bne	a0,s8,ffffffffc02032d8 <pmm_init+0xa80>
ffffffffc0202a80:	100027f3          	csrr	a5,sstatus
ffffffffc0202a84:	8b89                	andi	a5,a5,2
ffffffffc0202a86:	3e079b63          	bnez	a5,ffffffffc0202e7c <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a8a:	000b3783          	ld	a5,0(s6)
ffffffffc0202a8e:	4505                	li	a0,1
ffffffffc0202a90:	6f9c                	ld	a5,24(a5)
ffffffffc0202a92:	9782                	jalr	a5
ffffffffc0202a94:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202a96:	00093503          	ld	a0,0(s2)
ffffffffc0202a9a:	46d1                	li	a3,20
ffffffffc0202a9c:	6605                	lui	a2,0x1
ffffffffc0202a9e:	85e2                	mv	a1,s8
ffffffffc0202aa0:	cc3ff0ef          	jal	ffffffffc0202762 <page_insert>
ffffffffc0202aa4:	06051ae3          	bnez	a0,ffffffffc0203318 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202aa8:	00093503          	ld	a0,0(s2)
ffffffffc0202aac:	4601                	li	a2,0
ffffffffc0202aae:	6585                	lui	a1,0x1
ffffffffc0202ab0:	bb6ff0ef          	jal	ffffffffc0201e66 <get_pte>
ffffffffc0202ab4:	040502e3          	beqz	a0,ffffffffc02032f8 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc0202ab8:	611c                	ld	a5,0(a0)
ffffffffc0202aba:	0107f713          	andi	a4,a5,16
ffffffffc0202abe:	7e070163          	beqz	a4,ffffffffc02032a0 <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc0202ac2:	8b91                	andi	a5,a5,4
ffffffffc0202ac4:	7a078e63          	beqz	a5,ffffffffc0203280 <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202ac8:	00093503          	ld	a0,0(s2)
ffffffffc0202acc:	611c                	ld	a5,0(a0)
ffffffffc0202ace:	8bc1                	andi	a5,a5,16
ffffffffc0202ad0:	78078863          	beqz	a5,ffffffffc0203260 <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc0202ad4:	000c2703          	lw	a4,0(s8)
ffffffffc0202ad8:	4785                	li	a5,1
ffffffffc0202ada:	76f71363          	bne	a4,a5,ffffffffc0203240 <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202ade:	4681                	li	a3,0
ffffffffc0202ae0:	6605                	lui	a2,0x1
ffffffffc0202ae2:	85d2                	mv	a1,s4
ffffffffc0202ae4:	c7fff0ef          	jal	ffffffffc0202762 <page_insert>
ffffffffc0202ae8:	72051c63          	bnez	a0,ffffffffc0203220 <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc0202aec:	000a2703          	lw	a4,0(s4)
ffffffffc0202af0:	4789                	li	a5,2
ffffffffc0202af2:	70f71763          	bne	a4,a5,ffffffffc0203200 <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202af6:	000c2783          	lw	a5,0(s8)
ffffffffc0202afa:	6e079363          	bnez	a5,ffffffffc02031e0 <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202afe:	00093503          	ld	a0,0(s2)
ffffffffc0202b02:	4601                	li	a2,0
ffffffffc0202b04:	6585                	lui	a1,0x1
ffffffffc0202b06:	b60ff0ef          	jal	ffffffffc0201e66 <get_pte>
ffffffffc0202b0a:	6a050b63          	beqz	a0,ffffffffc02031c0 <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202b0e:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202b10:	00177793          	andi	a5,a4,1
ffffffffc0202b14:	4a078263          	beqz	a5,ffffffffc0202fb8 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202b18:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202b1a:	00271793          	slli	a5,a4,0x2
ffffffffc0202b1e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b20:	48d7fa63          	bgeu	a5,a3,ffffffffc0202fb4 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b24:	000bb683          	ld	a3,0(s7)
ffffffffc0202b28:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202b2c:	97d6                	add	a5,a5,s5
ffffffffc0202b2e:	079a                	slli	a5,a5,0x6
ffffffffc0202b30:	97b6                	add	a5,a5,a3
ffffffffc0202b32:	66fa1763          	bne	s4,a5,ffffffffc02031a0 <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202b36:	8b41                	andi	a4,a4,16
ffffffffc0202b38:	64071463          	bnez	a4,ffffffffc0203180 <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202b3c:	00093503          	ld	a0,0(s2)
ffffffffc0202b40:	4581                	li	a1,0
ffffffffc0202b42:	b85ff0ef          	jal	ffffffffc02026c6 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202b46:	000a2c83          	lw	s9,0(s4)
ffffffffc0202b4a:	4785                	li	a5,1
ffffffffc0202b4c:	60fc9a63          	bne	s9,a5,ffffffffc0203160 <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202b50:	000c2783          	lw	a5,0(s8)
ffffffffc0202b54:	5e079663          	bnez	a5,ffffffffc0203140 <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202b58:	00093503          	ld	a0,0(s2)
ffffffffc0202b5c:	6585                	lui	a1,0x1
ffffffffc0202b5e:	b69ff0ef          	jal	ffffffffc02026c6 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202b62:	000a2783          	lw	a5,0(s4)
ffffffffc0202b66:	52079d63          	bnez	a5,ffffffffc02030a0 <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202b6a:	000c2783          	lw	a5,0(s8)
ffffffffc0202b6e:	50079963          	bnez	a5,ffffffffc0203080 <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202b72:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b76:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b78:	000a3783          	ld	a5,0(s4)
ffffffffc0202b7c:	078a                	slli	a5,a5,0x2
ffffffffc0202b7e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b80:	42e7fa63          	bgeu	a5,a4,ffffffffc0202fb4 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b84:	000bb503          	ld	a0,0(s7)
ffffffffc0202b88:	97d6                	add	a5,a5,s5
ffffffffc0202b8a:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202b8c:	00f506b3          	add	a3,a0,a5
ffffffffc0202b90:	4294                	lw	a3,0(a3)
ffffffffc0202b92:	4d969763          	bne	a3,s9,ffffffffc0203060 <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202b96:	8799                	srai	a5,a5,0x6
ffffffffc0202b98:	00080637          	lui	a2,0x80
ffffffffc0202b9c:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b9e:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202ba2:	4ae7f363          	bgeu	a5,a4,ffffffffc0203048 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202ba6:	0009b783          	ld	a5,0(s3)
ffffffffc0202baa:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bac:	639c                	ld	a5,0(a5)
ffffffffc0202bae:	078a                	slli	a5,a5,0x2
ffffffffc0202bb0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bb2:	40e7f163          	bgeu	a5,a4,ffffffffc0202fb4 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bb6:	8f91                	sub	a5,a5,a2
ffffffffc0202bb8:	079a                	slli	a5,a5,0x6
ffffffffc0202bba:	953e                	add	a0,a0,a5
ffffffffc0202bbc:	100027f3          	csrr	a5,sstatus
ffffffffc0202bc0:	8b89                	andi	a5,a5,2
ffffffffc0202bc2:	30079863          	bnez	a5,ffffffffc0202ed2 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202bc6:	000b3783          	ld	a5,0(s6)
ffffffffc0202bca:	4585                	li	a1,1
ffffffffc0202bcc:	739c                	ld	a5,32(a5)
ffffffffc0202bce:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bd0:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202bd4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bd6:	078a                	slli	a5,a5,0x2
ffffffffc0202bd8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bda:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202fb4 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bde:	000bb503          	ld	a0,0(s7)
ffffffffc0202be2:	fe000737          	lui	a4,0xfe000
ffffffffc0202be6:	079a                	slli	a5,a5,0x6
ffffffffc0202be8:	97ba                	add	a5,a5,a4
ffffffffc0202bea:	953e                	add	a0,a0,a5
ffffffffc0202bec:	100027f3          	csrr	a5,sstatus
ffffffffc0202bf0:	8b89                	andi	a5,a5,2
ffffffffc0202bf2:	2c079463          	bnez	a5,ffffffffc0202eba <pmm_init+0x662>
ffffffffc0202bf6:	000b3783          	ld	a5,0(s6)
ffffffffc0202bfa:	4585                	li	a1,1
ffffffffc0202bfc:	739c                	ld	a5,32(a5)
ffffffffc0202bfe:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202c00:	00093783          	ld	a5,0(s2)
ffffffffc0202c04:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd49938>
    asm volatile("sfence.vma");
ffffffffc0202c08:	12000073          	sfence.vma
ffffffffc0202c0c:	100027f3          	csrr	a5,sstatus
ffffffffc0202c10:	8b89                	andi	a5,a5,2
ffffffffc0202c12:	28079a63          	bnez	a5,ffffffffc0202ea6 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c16:	000b3783          	ld	a5,0(s6)
ffffffffc0202c1a:	779c                	ld	a5,40(a5)
ffffffffc0202c1c:	9782                	jalr	a5
ffffffffc0202c1e:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c20:	4d441063          	bne	s0,s4,ffffffffc02030e0 <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202c24:	00004517          	auipc	a0,0x4
ffffffffc0202c28:	f5c50513          	addi	a0,a0,-164 # ffffffffc0206b80 <etext+0x12d8>
ffffffffc0202c2c:	d6cfd0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc0202c30:	100027f3          	csrr	a5,sstatus
ffffffffc0202c34:	8b89                	andi	a5,a5,2
ffffffffc0202c36:	24079e63          	bnez	a5,ffffffffc0202e92 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c3a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c3e:	779c                	ld	a5,40(a5)
ffffffffc0202c40:	9782                	jalr	a5
ffffffffc0202c42:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c44:	609c                	ld	a5,0(s1)
ffffffffc0202c46:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c4a:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c4c:	00c79713          	slli	a4,a5,0xc
ffffffffc0202c50:	6a85                	lui	s5,0x1
ffffffffc0202c52:	02e47c63          	bgeu	s0,a4,ffffffffc0202c8a <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202c56:	00c45713          	srli	a4,s0,0xc
ffffffffc0202c5a:	30f77063          	bgeu	a4,a5,ffffffffc0202f5a <pmm_init+0x702>
ffffffffc0202c5e:	0009b583          	ld	a1,0(s3)
ffffffffc0202c62:	00093503          	ld	a0,0(s2)
ffffffffc0202c66:	4601                	li	a2,0
ffffffffc0202c68:	95a2                	add	a1,a1,s0
ffffffffc0202c6a:	9fcff0ef          	jal	ffffffffc0201e66 <get_pte>
ffffffffc0202c6e:	32050363          	beqz	a0,ffffffffc0202f94 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c72:	611c                	ld	a5,0(a0)
ffffffffc0202c74:	078a                	slli	a5,a5,0x2
ffffffffc0202c76:	0147f7b3          	and	a5,a5,s4
ffffffffc0202c7a:	2e879d63          	bne	a5,s0,ffffffffc0202f74 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c7e:	609c                	ld	a5,0(s1)
ffffffffc0202c80:	9456                	add	s0,s0,s5
ffffffffc0202c82:	00c79713          	slli	a4,a5,0xc
ffffffffc0202c86:	fce468e3          	bltu	s0,a4,ffffffffc0202c56 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202c8a:	00093783          	ld	a5,0(s2)
ffffffffc0202c8e:	639c                	ld	a5,0(a5)
ffffffffc0202c90:	42079863          	bnez	a5,ffffffffc02030c0 <pmm_init+0x868>
ffffffffc0202c94:	100027f3          	csrr	a5,sstatus
ffffffffc0202c98:	8b89                	andi	a5,a5,2
ffffffffc0202c9a:	24079863          	bnez	a5,ffffffffc0202eea <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c9e:	000b3783          	ld	a5,0(s6)
ffffffffc0202ca2:	4505                	li	a0,1
ffffffffc0202ca4:	6f9c                	ld	a5,24(a5)
ffffffffc0202ca6:	9782                	jalr	a5
ffffffffc0202ca8:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202caa:	00093503          	ld	a0,0(s2)
ffffffffc0202cae:	4699                	li	a3,6
ffffffffc0202cb0:	10000613          	li	a2,256
ffffffffc0202cb4:	85a2                	mv	a1,s0
ffffffffc0202cb6:	aadff0ef          	jal	ffffffffc0202762 <page_insert>
ffffffffc0202cba:	46051363          	bnez	a0,ffffffffc0203120 <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202cbe:	4018                	lw	a4,0(s0)
ffffffffc0202cc0:	4785                	li	a5,1
ffffffffc0202cc2:	42f71f63          	bne	a4,a5,ffffffffc0203100 <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202cc6:	00093503          	ld	a0,0(s2)
ffffffffc0202cca:	6605                	lui	a2,0x1
ffffffffc0202ccc:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7e28>
ffffffffc0202cd0:	4699                	li	a3,6
ffffffffc0202cd2:	85a2                	mv	a1,s0
ffffffffc0202cd4:	a8fff0ef          	jal	ffffffffc0202762 <page_insert>
ffffffffc0202cd8:	72051963          	bnez	a0,ffffffffc020340a <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202cdc:	4018                	lw	a4,0(s0)
ffffffffc0202cde:	4789                	li	a5,2
ffffffffc0202ce0:	70f71563          	bne	a4,a5,ffffffffc02033ea <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202ce4:	00004597          	auipc	a1,0x4
ffffffffc0202ce8:	fe458593          	addi	a1,a1,-28 # ffffffffc0206cc8 <etext+0x1420>
ffffffffc0202cec:	10000513          	li	a0,256
ffffffffc0202cf0:	30f020ef          	jal	ffffffffc02057fe <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cf4:	6585                	lui	a1,0x1
ffffffffc0202cf6:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7e28>
ffffffffc0202cfa:	10000513          	li	a0,256
ffffffffc0202cfe:	313020ef          	jal	ffffffffc0205810 <strcmp>
ffffffffc0202d02:	6c051463          	bnez	a0,ffffffffc02033ca <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202d06:	000bb683          	ld	a3,0(s7)
ffffffffc0202d0a:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202d0e:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202d10:	40d406b3          	sub	a3,s0,a3
ffffffffc0202d14:	8699                	srai	a3,a3,0x6
ffffffffc0202d16:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202d18:	00c69793          	slli	a5,a3,0xc
ffffffffc0202d1c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202d1e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202d20:	32e7f463          	bgeu	a5,a4,ffffffffc0203048 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202d24:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202d28:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202d2c:	97b6                	add	a5,a5,a3
ffffffffc0202d2e:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_matrix_out_size+0x74bc0>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202d32:	299020ef          	jal	ffffffffc02057ca <strlen>
ffffffffc0202d36:	66051a63          	bnez	a0,ffffffffc02033aa <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202d3a:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202d3e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d40:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd49938>
ffffffffc0202d44:	078a                	slli	a5,a5,0x2
ffffffffc0202d46:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d48:	26e7f663          	bgeu	a5,a4,ffffffffc0202fb4 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202d4c:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202d50:	2ee7fc63          	bgeu	a5,a4,ffffffffc0203048 <pmm_init+0x7f0>
ffffffffc0202d54:	0009b783          	ld	a5,0(s3)
ffffffffc0202d58:	00f689b3          	add	s3,a3,a5
ffffffffc0202d5c:	100027f3          	csrr	a5,sstatus
ffffffffc0202d60:	8b89                	andi	a5,a5,2
ffffffffc0202d62:	1e079163          	bnez	a5,ffffffffc0202f44 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202d66:	000b3783          	ld	a5,0(s6)
ffffffffc0202d6a:	8522                	mv	a0,s0
ffffffffc0202d6c:	4585                	li	a1,1
ffffffffc0202d6e:	739c                	ld	a5,32(a5)
ffffffffc0202d70:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d72:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202d76:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d78:	078a                	slli	a5,a5,0x2
ffffffffc0202d7a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d7c:	22e7fc63          	bgeu	a5,a4,ffffffffc0202fb4 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d80:	000bb503          	ld	a0,0(s7)
ffffffffc0202d84:	fe000737          	lui	a4,0xfe000
ffffffffc0202d88:	079a                	slli	a5,a5,0x6
ffffffffc0202d8a:	97ba                	add	a5,a5,a4
ffffffffc0202d8c:	953e                	add	a0,a0,a5
ffffffffc0202d8e:	100027f3          	csrr	a5,sstatus
ffffffffc0202d92:	8b89                	andi	a5,a5,2
ffffffffc0202d94:	18079c63          	bnez	a5,ffffffffc0202f2c <pmm_init+0x6d4>
ffffffffc0202d98:	000b3783          	ld	a5,0(s6)
ffffffffc0202d9c:	4585                	li	a1,1
ffffffffc0202d9e:	739c                	ld	a5,32(a5)
ffffffffc0202da0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202da2:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202da6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202da8:	078a                	slli	a5,a5,0x2
ffffffffc0202daa:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202dac:	20e7f463          	bgeu	a5,a4,ffffffffc0202fb4 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202db0:	000bb503          	ld	a0,0(s7)
ffffffffc0202db4:	fe000737          	lui	a4,0xfe000
ffffffffc0202db8:	079a                	slli	a5,a5,0x6
ffffffffc0202dba:	97ba                	add	a5,a5,a4
ffffffffc0202dbc:	953e                	add	a0,a0,a5
ffffffffc0202dbe:	100027f3          	csrr	a5,sstatus
ffffffffc0202dc2:	8b89                	andi	a5,a5,2
ffffffffc0202dc4:	14079863          	bnez	a5,ffffffffc0202f14 <pmm_init+0x6bc>
ffffffffc0202dc8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dcc:	4585                	li	a1,1
ffffffffc0202dce:	739c                	ld	a5,32(a5)
ffffffffc0202dd0:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202dd2:	00093783          	ld	a5,0(s2)
ffffffffc0202dd6:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202dda:	12000073          	sfence.vma
ffffffffc0202dde:	100027f3          	csrr	a5,sstatus
ffffffffc0202de2:	8b89                	andi	a5,a5,2
ffffffffc0202de4:	10079e63          	bnez	a5,ffffffffc0202f00 <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202de8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dec:	779c                	ld	a5,40(a5)
ffffffffc0202dee:	9782                	jalr	a5
ffffffffc0202df0:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202df2:	1e8c1b63          	bne	s8,s0,ffffffffc0202fe8 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202df6:	00004517          	auipc	a0,0x4
ffffffffc0202dfa:	f4a50513          	addi	a0,a0,-182 # ffffffffc0206d40 <etext+0x1498>
ffffffffc0202dfe:	b9afd0ef          	jal	ffffffffc0200198 <cprintf>
}
ffffffffc0202e02:	7406                	ld	s0,96(sp)
ffffffffc0202e04:	70a6                	ld	ra,104(sp)
ffffffffc0202e06:	64e6                	ld	s1,88(sp)
ffffffffc0202e08:	6946                	ld	s2,80(sp)
ffffffffc0202e0a:	69a6                	ld	s3,72(sp)
ffffffffc0202e0c:	6a06                	ld	s4,64(sp)
ffffffffc0202e0e:	7ae2                	ld	s5,56(sp)
ffffffffc0202e10:	7b42                	ld	s6,48(sp)
ffffffffc0202e12:	7ba2                	ld	s7,40(sp)
ffffffffc0202e14:	7c02                	ld	s8,32(sp)
ffffffffc0202e16:	6ce2                	ld	s9,24(sp)
ffffffffc0202e18:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202e1a:	dbffe06f          	j	ffffffffc0201bd8 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202e1e:	853e                	mv	a0,a5
ffffffffc0202e20:	b4e1                	j	ffffffffc02028e8 <pmm_init+0x90>
        intr_disable();
ffffffffc0202e22:	addfd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e26:	000b3783          	ld	a5,0(s6)
ffffffffc0202e2a:	4505                	li	a0,1
ffffffffc0202e2c:	6f9c                	ld	a5,24(a5)
ffffffffc0202e2e:	9782                	jalr	a5
ffffffffc0202e30:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e32:	ac7fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202e36:	be75                	j	ffffffffc02029f2 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202e38:	ac7fd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e3c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e40:	779c                	ld	a5,40(a5)
ffffffffc0202e42:	9782                	jalr	a5
ffffffffc0202e44:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e46:	ab3fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202e4a:	b6ad                	j	ffffffffc02029b4 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202e4c:	6705                	lui	a4,0x1
ffffffffc0202e4e:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7f29>
ffffffffc0202e50:	96ba                	add	a3,a3,a4
ffffffffc0202e52:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202e54:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202e58:	14a77e63          	bgeu	a4,a0,ffffffffc0202fb4 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202e5c:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202e60:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202e62:	071a                	slli	a4,a4,0x6
ffffffffc0202e64:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202e68:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202e6a:	6a9c                	ld	a5,16(a3)
ffffffffc0202e6c:	00c45593          	srli	a1,s0,0xc
ffffffffc0202e70:	00e60533          	add	a0,a2,a4
ffffffffc0202e74:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202e76:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202e7a:	bcf1                	j	ffffffffc0202956 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202e7c:	a83fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e80:	000b3783          	ld	a5,0(s6)
ffffffffc0202e84:	4505                	li	a0,1
ffffffffc0202e86:	6f9c                	ld	a5,24(a5)
ffffffffc0202e88:	9782                	jalr	a5
ffffffffc0202e8a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e8c:	a6dfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202e90:	b119                	j	ffffffffc0202a96 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202e92:	a6dfd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e96:	000b3783          	ld	a5,0(s6)
ffffffffc0202e9a:	779c                	ld	a5,40(a5)
ffffffffc0202e9c:	9782                	jalr	a5
ffffffffc0202e9e:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202ea0:	a59fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202ea4:	b345                	j	ffffffffc0202c44 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202ea6:	a59fd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202eaa:	000b3783          	ld	a5,0(s6)
ffffffffc0202eae:	779c                	ld	a5,40(a5)
ffffffffc0202eb0:	9782                	jalr	a5
ffffffffc0202eb2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202eb4:	a45fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202eb8:	b3a5                	j	ffffffffc0202c20 <pmm_init+0x3c8>
ffffffffc0202eba:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ebc:	a43fd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ec0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ec4:	6522                	ld	a0,8(sp)
ffffffffc0202ec6:	4585                	li	a1,1
ffffffffc0202ec8:	739c                	ld	a5,32(a5)
ffffffffc0202eca:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ecc:	a2dfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202ed0:	bb05                	j	ffffffffc0202c00 <pmm_init+0x3a8>
ffffffffc0202ed2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ed4:	a2bfd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202ed8:	000b3783          	ld	a5,0(s6)
ffffffffc0202edc:	6522                	ld	a0,8(sp)
ffffffffc0202ede:	4585                	li	a1,1
ffffffffc0202ee0:	739c                	ld	a5,32(a5)
ffffffffc0202ee2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ee4:	a15fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202ee8:	b1e5                	j	ffffffffc0202bd0 <pmm_init+0x378>
        intr_disable();
ffffffffc0202eea:	a15fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202eee:	000b3783          	ld	a5,0(s6)
ffffffffc0202ef2:	4505                	li	a0,1
ffffffffc0202ef4:	6f9c                	ld	a5,24(a5)
ffffffffc0202ef6:	9782                	jalr	a5
ffffffffc0202ef8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202efa:	9fffd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202efe:	b375                	j	ffffffffc0202caa <pmm_init+0x452>
        intr_disable();
ffffffffc0202f00:	9fffd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f04:	000b3783          	ld	a5,0(s6)
ffffffffc0202f08:	779c                	ld	a5,40(a5)
ffffffffc0202f0a:	9782                	jalr	a5
ffffffffc0202f0c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202f0e:	9ebfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202f12:	b5c5                	j	ffffffffc0202df2 <pmm_init+0x59a>
ffffffffc0202f14:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202f16:	9e9fd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202f1a:	000b3783          	ld	a5,0(s6)
ffffffffc0202f1e:	6522                	ld	a0,8(sp)
ffffffffc0202f20:	4585                	li	a1,1
ffffffffc0202f22:	739c                	ld	a5,32(a5)
ffffffffc0202f24:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f26:	9d3fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202f2a:	b565                	j	ffffffffc0202dd2 <pmm_init+0x57a>
ffffffffc0202f2c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202f2e:	9d1fd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202f32:	000b3783          	ld	a5,0(s6)
ffffffffc0202f36:	6522                	ld	a0,8(sp)
ffffffffc0202f38:	4585                	li	a1,1
ffffffffc0202f3a:	739c                	ld	a5,32(a5)
ffffffffc0202f3c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f3e:	9bbfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202f42:	b585                	j	ffffffffc0202da2 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202f44:	9bbfd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202f48:	000b3783          	ld	a5,0(s6)
ffffffffc0202f4c:	8522                	mv	a0,s0
ffffffffc0202f4e:	4585                	li	a1,1
ffffffffc0202f50:	739c                	ld	a5,32(a5)
ffffffffc0202f52:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f54:	9a5fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202f58:	bd29                	j	ffffffffc0202d72 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f5a:	86a2                	mv	a3,s0
ffffffffc0202f5c:	00003617          	auipc	a2,0x3
ffffffffc0202f60:	6dc60613          	addi	a2,a2,1756 # ffffffffc0206638 <etext+0xd90>
ffffffffc0202f64:	24d00593          	li	a1,589
ffffffffc0202f68:	00003517          	auipc	a0,0x3
ffffffffc0202f6c:	7c050513          	addi	a0,a0,1984 # ffffffffc0206728 <etext+0xe80>
ffffffffc0202f70:	cdafd0ef          	jal	ffffffffc020044a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f74:	00004697          	auipc	a3,0x4
ffffffffc0202f78:	c6c68693          	addi	a3,a3,-916 # ffffffffc0206be0 <etext+0x1338>
ffffffffc0202f7c:	00003617          	auipc	a2,0x3
ffffffffc0202f80:	30c60613          	addi	a2,a2,780 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0202f84:	24e00593          	li	a1,590
ffffffffc0202f88:	00003517          	auipc	a0,0x3
ffffffffc0202f8c:	7a050513          	addi	a0,a0,1952 # ffffffffc0206728 <etext+0xe80>
ffffffffc0202f90:	cbafd0ef          	jal	ffffffffc020044a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f94:	00004697          	auipc	a3,0x4
ffffffffc0202f98:	c0c68693          	addi	a3,a3,-1012 # ffffffffc0206ba0 <etext+0x12f8>
ffffffffc0202f9c:	00003617          	auipc	a2,0x3
ffffffffc0202fa0:	2ec60613          	addi	a2,a2,748 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0202fa4:	24d00593          	li	a1,589
ffffffffc0202fa8:	00003517          	auipc	a0,0x3
ffffffffc0202fac:	78050513          	addi	a0,a0,1920 # ffffffffc0206728 <etext+0xe80>
ffffffffc0202fb0:	c9afd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0202fb4:	deffe0ef          	jal	ffffffffc0201da2 <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202fb8:	00003617          	auipc	a2,0x3
ffffffffc0202fbc:	7c860613          	addi	a2,a2,1992 # ffffffffc0206780 <etext+0xed8>
ffffffffc0202fc0:	07f00593          	li	a1,127
ffffffffc0202fc4:	00003517          	auipc	a0,0x3
ffffffffc0202fc8:	69c50513          	addi	a0,a0,1692 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0202fcc:	c7efd0ef          	jal	ffffffffc020044a <__panic>
        panic("DTB memory info not available");
ffffffffc0202fd0:	00004617          	auipc	a2,0x4
ffffffffc0202fd4:	81060613          	addi	a2,a2,-2032 # ffffffffc02067e0 <etext+0xf38>
ffffffffc0202fd8:	06500593          	li	a1,101
ffffffffc0202fdc:	00003517          	auipc	a0,0x3
ffffffffc0202fe0:	74c50513          	addi	a0,a0,1868 # ffffffffc0206728 <etext+0xe80>
ffffffffc0202fe4:	c66fd0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202fe8:	00004697          	auipc	a3,0x4
ffffffffc0202fec:	b7068693          	addi	a3,a3,-1168 # ffffffffc0206b58 <etext+0x12b0>
ffffffffc0202ff0:	00003617          	auipc	a2,0x3
ffffffffc0202ff4:	29860613          	addi	a2,a2,664 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0202ff8:	26800593          	li	a1,616
ffffffffc0202ffc:	00003517          	auipc	a0,0x3
ffffffffc0203000:	72c50513          	addi	a0,a0,1836 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203004:	c46fd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0203008:	00004697          	auipc	a3,0x4
ffffffffc020300c:	89068693          	addi	a3,a3,-1904 # ffffffffc0206898 <etext+0xff0>
ffffffffc0203010:	00003617          	auipc	a2,0x3
ffffffffc0203014:	27860613          	addi	a2,a2,632 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203018:	20f00593          	li	a1,527
ffffffffc020301c:	00003517          	auipc	a0,0x3
ffffffffc0203020:	70c50513          	addi	a0,a0,1804 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203024:	c26fd0ef          	jal	ffffffffc020044a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203028:	00004697          	auipc	a3,0x4
ffffffffc020302c:	85068693          	addi	a3,a3,-1968 # ffffffffc0206878 <etext+0xfd0>
ffffffffc0203030:	00003617          	auipc	a2,0x3
ffffffffc0203034:	25860613          	addi	a2,a2,600 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203038:	20e00593          	li	a1,526
ffffffffc020303c:	00003517          	auipc	a0,0x3
ffffffffc0203040:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203044:	c06fd0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc0203048:	00003617          	auipc	a2,0x3
ffffffffc020304c:	5f060613          	addi	a2,a2,1520 # ffffffffc0206638 <etext+0xd90>
ffffffffc0203050:	07100593          	li	a1,113
ffffffffc0203054:	00003517          	auipc	a0,0x3
ffffffffc0203058:	60c50513          	addi	a0,a0,1548 # ffffffffc0206660 <etext+0xdb8>
ffffffffc020305c:	beefd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0203060:	00004697          	auipc	a3,0x4
ffffffffc0203064:	ac868693          	addi	a3,a3,-1336 # ffffffffc0206b28 <etext+0x1280>
ffffffffc0203068:	00003617          	auipc	a2,0x3
ffffffffc020306c:	22060613          	addi	a2,a2,544 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203070:	23600593          	li	a1,566
ffffffffc0203074:	00003517          	auipc	a0,0x3
ffffffffc0203078:	6b450513          	addi	a0,a0,1716 # ffffffffc0206728 <etext+0xe80>
ffffffffc020307c:	bcefd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203080:	00004697          	auipc	a3,0x4
ffffffffc0203084:	a6068693          	addi	a3,a3,-1440 # ffffffffc0206ae0 <etext+0x1238>
ffffffffc0203088:	00003617          	auipc	a2,0x3
ffffffffc020308c:	20060613          	addi	a2,a2,512 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203090:	23400593          	li	a1,564
ffffffffc0203094:	00003517          	auipc	a0,0x3
ffffffffc0203098:	69450513          	addi	a0,a0,1684 # ffffffffc0206728 <etext+0xe80>
ffffffffc020309c:	baefd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02030a0:	00004697          	auipc	a3,0x4
ffffffffc02030a4:	a7068693          	addi	a3,a3,-1424 # ffffffffc0206b10 <etext+0x1268>
ffffffffc02030a8:	00003617          	auipc	a2,0x3
ffffffffc02030ac:	1e060613          	addi	a2,a2,480 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02030b0:	23300593          	li	a1,563
ffffffffc02030b4:	00003517          	auipc	a0,0x3
ffffffffc02030b8:	67450513          	addi	a0,a0,1652 # ffffffffc0206728 <etext+0xe80>
ffffffffc02030bc:	b8efd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02030c0:	00004697          	auipc	a3,0x4
ffffffffc02030c4:	b3868693          	addi	a3,a3,-1224 # ffffffffc0206bf8 <etext+0x1350>
ffffffffc02030c8:	00003617          	auipc	a2,0x3
ffffffffc02030cc:	1c060613          	addi	a2,a2,448 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02030d0:	25100593          	li	a1,593
ffffffffc02030d4:	00003517          	auipc	a0,0x3
ffffffffc02030d8:	65450513          	addi	a0,a0,1620 # ffffffffc0206728 <etext+0xe80>
ffffffffc02030dc:	b6efd0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02030e0:	00004697          	auipc	a3,0x4
ffffffffc02030e4:	a7868693          	addi	a3,a3,-1416 # ffffffffc0206b58 <etext+0x12b0>
ffffffffc02030e8:	00003617          	auipc	a2,0x3
ffffffffc02030ec:	1a060613          	addi	a2,a2,416 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02030f0:	23e00593          	li	a1,574
ffffffffc02030f4:	00003517          	auipc	a0,0x3
ffffffffc02030f8:	63450513          	addi	a0,a0,1588 # ffffffffc0206728 <etext+0xe80>
ffffffffc02030fc:	b4efd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203100:	00004697          	auipc	a3,0x4
ffffffffc0203104:	b5068693          	addi	a3,a3,-1200 # ffffffffc0206c50 <etext+0x13a8>
ffffffffc0203108:	00003617          	auipc	a2,0x3
ffffffffc020310c:	18060613          	addi	a2,a2,384 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203110:	25600593          	li	a1,598
ffffffffc0203114:	00003517          	auipc	a0,0x3
ffffffffc0203118:	61450513          	addi	a0,a0,1556 # ffffffffc0206728 <etext+0xe80>
ffffffffc020311c:	b2efd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203120:	00004697          	auipc	a3,0x4
ffffffffc0203124:	af068693          	addi	a3,a3,-1296 # ffffffffc0206c10 <etext+0x1368>
ffffffffc0203128:	00003617          	auipc	a2,0x3
ffffffffc020312c:	16060613          	addi	a2,a2,352 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203130:	25500593          	li	a1,597
ffffffffc0203134:	00003517          	auipc	a0,0x3
ffffffffc0203138:	5f450513          	addi	a0,a0,1524 # ffffffffc0206728 <etext+0xe80>
ffffffffc020313c:	b0efd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203140:	00004697          	auipc	a3,0x4
ffffffffc0203144:	9a068693          	addi	a3,a3,-1632 # ffffffffc0206ae0 <etext+0x1238>
ffffffffc0203148:	00003617          	auipc	a2,0x3
ffffffffc020314c:	14060613          	addi	a2,a2,320 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203150:	23000593          	li	a1,560
ffffffffc0203154:	00003517          	auipc	a0,0x3
ffffffffc0203158:	5d450513          	addi	a0,a0,1492 # ffffffffc0206728 <etext+0xe80>
ffffffffc020315c:	aeefd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203160:	00004697          	auipc	a3,0x4
ffffffffc0203164:	82068693          	addi	a3,a3,-2016 # ffffffffc0206980 <etext+0x10d8>
ffffffffc0203168:	00003617          	auipc	a2,0x3
ffffffffc020316c:	12060613          	addi	a2,a2,288 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203170:	22f00593          	li	a1,559
ffffffffc0203174:	00003517          	auipc	a0,0x3
ffffffffc0203178:	5b450513          	addi	a0,a0,1460 # ffffffffc0206728 <etext+0xe80>
ffffffffc020317c:	acefd0ef          	jal	ffffffffc020044a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203180:	00004697          	auipc	a3,0x4
ffffffffc0203184:	97868693          	addi	a3,a3,-1672 # ffffffffc0206af8 <etext+0x1250>
ffffffffc0203188:	00003617          	auipc	a2,0x3
ffffffffc020318c:	10060613          	addi	a2,a2,256 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203190:	22c00593          	li	a1,556
ffffffffc0203194:	00003517          	auipc	a0,0x3
ffffffffc0203198:	59450513          	addi	a0,a0,1428 # ffffffffc0206728 <etext+0xe80>
ffffffffc020319c:	aaefd0ef          	jal	ffffffffc020044a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02031a0:	00003697          	auipc	a3,0x3
ffffffffc02031a4:	7c868693          	addi	a3,a3,1992 # ffffffffc0206968 <etext+0x10c0>
ffffffffc02031a8:	00003617          	auipc	a2,0x3
ffffffffc02031ac:	0e060613          	addi	a2,a2,224 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02031b0:	22b00593          	li	a1,555
ffffffffc02031b4:	00003517          	auipc	a0,0x3
ffffffffc02031b8:	57450513          	addi	a0,a0,1396 # ffffffffc0206728 <etext+0xe80>
ffffffffc02031bc:	a8efd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02031c0:	00004697          	auipc	a3,0x4
ffffffffc02031c4:	84868693          	addi	a3,a3,-1976 # ffffffffc0206a08 <etext+0x1160>
ffffffffc02031c8:	00003617          	auipc	a2,0x3
ffffffffc02031cc:	0c060613          	addi	a2,a2,192 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02031d0:	22a00593          	li	a1,554
ffffffffc02031d4:	00003517          	auipc	a0,0x3
ffffffffc02031d8:	55450513          	addi	a0,a0,1364 # ffffffffc0206728 <etext+0xe80>
ffffffffc02031dc:	a6efd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02031e0:	00004697          	auipc	a3,0x4
ffffffffc02031e4:	90068693          	addi	a3,a3,-1792 # ffffffffc0206ae0 <etext+0x1238>
ffffffffc02031e8:	00003617          	auipc	a2,0x3
ffffffffc02031ec:	0a060613          	addi	a2,a2,160 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02031f0:	22900593          	li	a1,553
ffffffffc02031f4:	00003517          	auipc	a0,0x3
ffffffffc02031f8:	53450513          	addi	a0,a0,1332 # ffffffffc0206728 <etext+0xe80>
ffffffffc02031fc:	a4efd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203200:	00004697          	auipc	a3,0x4
ffffffffc0203204:	8c868693          	addi	a3,a3,-1848 # ffffffffc0206ac8 <etext+0x1220>
ffffffffc0203208:	00003617          	auipc	a2,0x3
ffffffffc020320c:	08060613          	addi	a2,a2,128 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203210:	22800593          	li	a1,552
ffffffffc0203214:	00003517          	auipc	a0,0x3
ffffffffc0203218:	51450513          	addi	a0,a0,1300 # ffffffffc0206728 <etext+0xe80>
ffffffffc020321c:	a2efd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203220:	00004697          	auipc	a3,0x4
ffffffffc0203224:	87868693          	addi	a3,a3,-1928 # ffffffffc0206a98 <etext+0x11f0>
ffffffffc0203228:	00003617          	auipc	a2,0x3
ffffffffc020322c:	06060613          	addi	a2,a2,96 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203230:	22700593          	li	a1,551
ffffffffc0203234:	00003517          	auipc	a0,0x3
ffffffffc0203238:	4f450513          	addi	a0,a0,1268 # ffffffffc0206728 <etext+0xe80>
ffffffffc020323c:	a0efd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203240:	00004697          	auipc	a3,0x4
ffffffffc0203244:	84068693          	addi	a3,a3,-1984 # ffffffffc0206a80 <etext+0x11d8>
ffffffffc0203248:	00003617          	auipc	a2,0x3
ffffffffc020324c:	04060613          	addi	a2,a2,64 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203250:	22500593          	li	a1,549
ffffffffc0203254:	00003517          	auipc	a0,0x3
ffffffffc0203258:	4d450513          	addi	a0,a0,1236 # ffffffffc0206728 <etext+0xe80>
ffffffffc020325c:	9eefd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203260:	00004697          	auipc	a3,0x4
ffffffffc0203264:	80068693          	addi	a3,a3,-2048 # ffffffffc0206a60 <etext+0x11b8>
ffffffffc0203268:	00003617          	auipc	a2,0x3
ffffffffc020326c:	02060613          	addi	a2,a2,32 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203270:	22400593          	li	a1,548
ffffffffc0203274:	00003517          	auipc	a0,0x3
ffffffffc0203278:	4b450513          	addi	a0,a0,1204 # ffffffffc0206728 <etext+0xe80>
ffffffffc020327c:	9cefd0ef          	jal	ffffffffc020044a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203280:	00003697          	auipc	a3,0x3
ffffffffc0203284:	7d068693          	addi	a3,a3,2000 # ffffffffc0206a50 <etext+0x11a8>
ffffffffc0203288:	00003617          	auipc	a2,0x3
ffffffffc020328c:	00060613          	mv	a2,a2
ffffffffc0203290:	22300593          	li	a1,547
ffffffffc0203294:	00003517          	auipc	a0,0x3
ffffffffc0203298:	49450513          	addi	a0,a0,1172 # ffffffffc0206728 <etext+0xe80>
ffffffffc020329c:	9aefd0ef          	jal	ffffffffc020044a <__panic>
    assert(*ptep & PTE_U);
ffffffffc02032a0:	00003697          	auipc	a3,0x3
ffffffffc02032a4:	7a068693          	addi	a3,a3,1952 # ffffffffc0206a40 <etext+0x1198>
ffffffffc02032a8:	00003617          	auipc	a2,0x3
ffffffffc02032ac:	fe060613          	addi	a2,a2,-32 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02032b0:	22200593          	li	a1,546
ffffffffc02032b4:	00003517          	auipc	a0,0x3
ffffffffc02032b8:	47450513          	addi	a0,a0,1140 # ffffffffc0206728 <etext+0xe80>
ffffffffc02032bc:	98efd0ef          	jal	ffffffffc020044a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02032c0:	00003617          	auipc	a2,0x3
ffffffffc02032c4:	42060613          	addi	a2,a2,1056 # ffffffffc02066e0 <etext+0xe38>
ffffffffc02032c8:	08100593          	li	a1,129
ffffffffc02032cc:	00003517          	auipc	a0,0x3
ffffffffc02032d0:	45c50513          	addi	a0,a0,1116 # ffffffffc0206728 <etext+0xe80>
ffffffffc02032d4:	976fd0ef          	jal	ffffffffc020044a <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02032d8:	00003697          	auipc	a3,0x3
ffffffffc02032dc:	6c068693          	addi	a3,a3,1728 # ffffffffc0206998 <etext+0x10f0>
ffffffffc02032e0:	00003617          	auipc	a2,0x3
ffffffffc02032e4:	fa860613          	addi	a2,a2,-88 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02032e8:	21d00593          	li	a1,541
ffffffffc02032ec:	00003517          	auipc	a0,0x3
ffffffffc02032f0:	43c50513          	addi	a0,a0,1084 # ffffffffc0206728 <etext+0xe80>
ffffffffc02032f4:	956fd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02032f8:	00003697          	auipc	a3,0x3
ffffffffc02032fc:	71068693          	addi	a3,a3,1808 # ffffffffc0206a08 <etext+0x1160>
ffffffffc0203300:	00003617          	auipc	a2,0x3
ffffffffc0203304:	f8860613          	addi	a2,a2,-120 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203308:	22100593          	li	a1,545
ffffffffc020330c:	00003517          	auipc	a0,0x3
ffffffffc0203310:	41c50513          	addi	a0,a0,1052 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203314:	936fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203318:	00003697          	auipc	a3,0x3
ffffffffc020331c:	6b068693          	addi	a3,a3,1712 # ffffffffc02069c8 <etext+0x1120>
ffffffffc0203320:	00003617          	auipc	a2,0x3
ffffffffc0203324:	f6860613          	addi	a2,a2,-152 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203328:	22000593          	li	a1,544
ffffffffc020332c:	00003517          	auipc	a0,0x3
ffffffffc0203330:	3fc50513          	addi	a0,a0,1020 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203334:	916fd0ef          	jal	ffffffffc020044a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203338:	86d6                	mv	a3,s5
ffffffffc020333a:	00003617          	auipc	a2,0x3
ffffffffc020333e:	2fe60613          	addi	a2,a2,766 # ffffffffc0206638 <etext+0xd90>
ffffffffc0203342:	21c00593          	li	a1,540
ffffffffc0203346:	00003517          	auipc	a0,0x3
ffffffffc020334a:	3e250513          	addi	a0,a0,994 # ffffffffc0206728 <etext+0xe80>
ffffffffc020334e:	8fcfd0ef          	jal	ffffffffc020044a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203352:	00003617          	auipc	a2,0x3
ffffffffc0203356:	2e660613          	addi	a2,a2,742 # ffffffffc0206638 <etext+0xd90>
ffffffffc020335a:	21b00593          	li	a1,539
ffffffffc020335e:	00003517          	auipc	a0,0x3
ffffffffc0203362:	3ca50513          	addi	a0,a0,970 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203366:	8e4fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020336a:	00003697          	auipc	a3,0x3
ffffffffc020336e:	61668693          	addi	a3,a3,1558 # ffffffffc0206980 <etext+0x10d8>
ffffffffc0203372:	00003617          	auipc	a2,0x3
ffffffffc0203376:	f1660613          	addi	a2,a2,-234 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020337a:	21900593          	li	a1,537
ffffffffc020337e:	00003517          	auipc	a0,0x3
ffffffffc0203382:	3aa50513          	addi	a0,a0,938 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203386:	8c4fd0ef          	jal	ffffffffc020044a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020338a:	00003697          	auipc	a3,0x3
ffffffffc020338e:	5de68693          	addi	a3,a3,1502 # ffffffffc0206968 <etext+0x10c0>
ffffffffc0203392:	00003617          	auipc	a2,0x3
ffffffffc0203396:	ef660613          	addi	a2,a2,-266 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020339a:	21800593          	li	a1,536
ffffffffc020339e:	00003517          	auipc	a0,0x3
ffffffffc02033a2:	38a50513          	addi	a0,a0,906 # ffffffffc0206728 <etext+0xe80>
ffffffffc02033a6:	8a4fd0ef          	jal	ffffffffc020044a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02033aa:	00004697          	auipc	a3,0x4
ffffffffc02033ae:	96e68693          	addi	a3,a3,-1682 # ffffffffc0206d18 <etext+0x1470>
ffffffffc02033b2:	00003617          	auipc	a2,0x3
ffffffffc02033b6:	ed660613          	addi	a2,a2,-298 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02033ba:	25f00593          	li	a1,607
ffffffffc02033be:	00003517          	auipc	a0,0x3
ffffffffc02033c2:	36a50513          	addi	a0,a0,874 # ffffffffc0206728 <etext+0xe80>
ffffffffc02033c6:	884fd0ef          	jal	ffffffffc020044a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02033ca:	00004697          	auipc	a3,0x4
ffffffffc02033ce:	91668693          	addi	a3,a3,-1770 # ffffffffc0206ce0 <etext+0x1438>
ffffffffc02033d2:	00003617          	auipc	a2,0x3
ffffffffc02033d6:	eb660613          	addi	a2,a2,-330 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02033da:	25c00593          	li	a1,604
ffffffffc02033de:	00003517          	auipc	a0,0x3
ffffffffc02033e2:	34a50513          	addi	a0,a0,842 # ffffffffc0206728 <etext+0xe80>
ffffffffc02033e6:	864fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p) == 2);
ffffffffc02033ea:	00004697          	auipc	a3,0x4
ffffffffc02033ee:	8c668693          	addi	a3,a3,-1850 # ffffffffc0206cb0 <etext+0x1408>
ffffffffc02033f2:	00003617          	auipc	a2,0x3
ffffffffc02033f6:	e9660613          	addi	a2,a2,-362 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02033fa:	25800593          	li	a1,600
ffffffffc02033fe:	00003517          	auipc	a0,0x3
ffffffffc0203402:	32a50513          	addi	a0,a0,810 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203406:	844fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020340a:	00004697          	auipc	a3,0x4
ffffffffc020340e:	85e68693          	addi	a3,a3,-1954 # ffffffffc0206c68 <etext+0x13c0>
ffffffffc0203412:	00003617          	auipc	a2,0x3
ffffffffc0203416:	e7660613          	addi	a2,a2,-394 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020341a:	25700593          	li	a1,599
ffffffffc020341e:	00003517          	auipc	a0,0x3
ffffffffc0203422:	30a50513          	addi	a0,a0,778 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203426:	824fd0ef          	jal	ffffffffc020044a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020342a:	00003697          	auipc	a3,0x3
ffffffffc020342e:	4ae68693          	addi	a3,a3,1198 # ffffffffc02068d8 <etext+0x1030>
ffffffffc0203432:	00003617          	auipc	a2,0x3
ffffffffc0203436:	e5660613          	addi	a2,a2,-426 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020343a:	21000593          	li	a1,528
ffffffffc020343e:	00003517          	auipc	a0,0x3
ffffffffc0203442:	2ea50513          	addi	a0,a0,746 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203446:	804fd0ef          	jal	ffffffffc020044a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020344a:	00003617          	auipc	a2,0x3
ffffffffc020344e:	29660613          	addi	a2,a2,662 # ffffffffc02066e0 <etext+0xe38>
ffffffffc0203452:	0c900593          	li	a1,201
ffffffffc0203456:	00003517          	auipc	a0,0x3
ffffffffc020345a:	2d250513          	addi	a0,a0,722 # ffffffffc0206728 <etext+0xe80>
ffffffffc020345e:	fedfc0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203462:	00003697          	auipc	a3,0x3
ffffffffc0203466:	4d668693          	addi	a3,a3,1238 # ffffffffc0206938 <etext+0x1090>
ffffffffc020346a:	00003617          	auipc	a2,0x3
ffffffffc020346e:	e1e60613          	addi	a2,a2,-482 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203472:	21700593          	li	a1,535
ffffffffc0203476:	00003517          	auipc	a0,0x3
ffffffffc020347a:	2b250513          	addi	a0,a0,690 # ffffffffc0206728 <etext+0xe80>
ffffffffc020347e:	fcdfc0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203482:	00003697          	auipc	a3,0x3
ffffffffc0203486:	48668693          	addi	a3,a3,1158 # ffffffffc0206908 <etext+0x1060>
ffffffffc020348a:	00003617          	auipc	a2,0x3
ffffffffc020348e:	dfe60613          	addi	a2,a2,-514 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203492:	21400593          	li	a1,532
ffffffffc0203496:	00003517          	auipc	a0,0x3
ffffffffc020349a:	29250513          	addi	a0,a0,658 # ffffffffc0206728 <etext+0xe80>
ffffffffc020349e:	fadfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02034a2 <pgdir_alloc_page>:
{
ffffffffc02034a2:	7139                	addi	sp,sp,-64
ffffffffc02034a4:	f426                	sd	s1,40(sp)
ffffffffc02034a6:	f04a                	sd	s2,32(sp)
ffffffffc02034a8:	ec4e                	sd	s3,24(sp)
ffffffffc02034aa:	fc06                	sd	ra,56(sp)
ffffffffc02034ac:	f822                	sd	s0,48(sp)
ffffffffc02034ae:	892a                	mv	s2,a0
ffffffffc02034b0:	84ae                	mv	s1,a1
ffffffffc02034b2:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034b4:	100027f3          	csrr	a5,sstatus
ffffffffc02034b8:	8b89                	andi	a5,a5,2
ffffffffc02034ba:	ebb5                	bnez	a5,ffffffffc020352e <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034bc:	000b2417          	auipc	s0,0xb2
ffffffffc02034c0:	1ac40413          	addi	s0,s0,428 # ffffffffc02b5668 <pmm_manager>
ffffffffc02034c4:	601c                	ld	a5,0(s0)
ffffffffc02034c6:	4505                	li	a0,1
ffffffffc02034c8:	6f9c                	ld	a5,24(a5)
ffffffffc02034ca:	9782                	jalr	a5
ffffffffc02034cc:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc02034ce:	c5b9                	beqz	a1,ffffffffc020351c <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02034d0:	86ce                	mv	a3,s3
ffffffffc02034d2:	854a                	mv	a0,s2
ffffffffc02034d4:	8626                	mv	a2,s1
ffffffffc02034d6:	e42e                	sd	a1,8(sp)
ffffffffc02034d8:	a8aff0ef          	jal	ffffffffc0202762 <page_insert>
ffffffffc02034dc:	65a2                	ld	a1,8(sp)
ffffffffc02034de:	e515                	bnez	a0,ffffffffc020350a <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc02034e0:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc02034e2:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc02034e4:	4785                	li	a5,1
ffffffffc02034e6:	02f70c63          	beq	a4,a5,ffffffffc020351e <pgdir_alloc_page+0x7c>
ffffffffc02034ea:	00004697          	auipc	a3,0x4
ffffffffc02034ee:	87668693          	addi	a3,a3,-1930 # ffffffffc0206d60 <etext+0x14b8>
ffffffffc02034f2:	00003617          	auipc	a2,0x3
ffffffffc02034f6:	d9660613          	addi	a2,a2,-618 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02034fa:	1f500593          	li	a1,501
ffffffffc02034fe:	00003517          	auipc	a0,0x3
ffffffffc0203502:	22a50513          	addi	a0,a0,554 # ffffffffc0206728 <etext+0xe80>
ffffffffc0203506:	f45fc0ef          	jal	ffffffffc020044a <__panic>
ffffffffc020350a:	100027f3          	csrr	a5,sstatus
ffffffffc020350e:	8b89                	andi	a5,a5,2
ffffffffc0203510:	ef95                	bnez	a5,ffffffffc020354c <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc0203512:	601c                	ld	a5,0(s0)
ffffffffc0203514:	852e                	mv	a0,a1
ffffffffc0203516:	4585                	li	a1,1
ffffffffc0203518:	739c                	ld	a5,32(a5)
ffffffffc020351a:	9782                	jalr	a5
            return NULL;
ffffffffc020351c:	4581                	li	a1,0
}
ffffffffc020351e:	70e2                	ld	ra,56(sp)
ffffffffc0203520:	7442                	ld	s0,48(sp)
ffffffffc0203522:	74a2                	ld	s1,40(sp)
ffffffffc0203524:	7902                	ld	s2,32(sp)
ffffffffc0203526:	69e2                	ld	s3,24(sp)
ffffffffc0203528:	852e                	mv	a0,a1
ffffffffc020352a:	6121                	addi	sp,sp,64
ffffffffc020352c:	8082                	ret
        intr_disable();
ffffffffc020352e:	bd0fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203532:	000b2417          	auipc	s0,0xb2
ffffffffc0203536:	13640413          	addi	s0,s0,310 # ffffffffc02b5668 <pmm_manager>
ffffffffc020353a:	601c                	ld	a5,0(s0)
ffffffffc020353c:	4505                	li	a0,1
ffffffffc020353e:	6f9c                	ld	a5,24(a5)
ffffffffc0203540:	9782                	jalr	a5
ffffffffc0203542:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0203544:	bb4fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0203548:	65a2                	ld	a1,8(sp)
ffffffffc020354a:	b751                	j	ffffffffc02034ce <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc020354c:	bb2fd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203550:	601c                	ld	a5,0(s0)
ffffffffc0203552:	6522                	ld	a0,8(sp)
ffffffffc0203554:	4585                	li	a1,1
ffffffffc0203556:	739c                	ld	a5,32(a5)
ffffffffc0203558:	9782                	jalr	a5
        intr_enable();
ffffffffc020355a:	b9efd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020355e:	bf7d                	j	ffffffffc020351c <pgdir_alloc_page+0x7a>

ffffffffc0203560 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203560:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203562:	00004697          	auipc	a3,0x4
ffffffffc0203566:	81668693          	addi	a3,a3,-2026 # ffffffffc0206d78 <etext+0x14d0>
ffffffffc020356a:	00003617          	auipc	a2,0x3
ffffffffc020356e:	d1e60613          	addi	a2,a2,-738 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203572:	07400593          	li	a1,116
ffffffffc0203576:	00004517          	auipc	a0,0x4
ffffffffc020357a:	82250513          	addi	a0,a0,-2014 # ffffffffc0206d98 <etext+0x14f0>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020357e:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203580:	ecbfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203584 <mm_create>:
{
ffffffffc0203584:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203586:	04000513          	li	a0,64
{
ffffffffc020358a:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020358c:	e70fe0ef          	jal	ffffffffc0201bfc <kmalloc>
    if (mm != NULL)
ffffffffc0203590:	cd19                	beqz	a0,ffffffffc02035ae <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203592:	e508                	sd	a0,8(a0)
ffffffffc0203594:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203596:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020359a:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020359e:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02035a2:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02035a6:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02035aa:	02053c23          	sd	zero,56(a0)
}
ffffffffc02035ae:	60a2                	ld	ra,8(sp)
ffffffffc02035b0:	0141                	addi	sp,sp,16
ffffffffc02035b2:	8082                	ret

ffffffffc02035b4 <find_vma>:
    if (mm != NULL)
ffffffffc02035b4:	c505                	beqz	a0,ffffffffc02035dc <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc02035b6:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02035b8:	c781                	beqz	a5,ffffffffc02035c0 <find_vma+0xc>
ffffffffc02035ba:	6798                	ld	a4,8(a5)
ffffffffc02035bc:	02e5f363          	bgeu	a1,a4,ffffffffc02035e2 <find_vma+0x2e>
    return listelm->next;
ffffffffc02035c0:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc02035c2:	00f50d63          	beq	a0,a5,ffffffffc02035dc <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02035c6:	fe87b703          	ld	a4,-24(a5) # fffffffffdffffe8 <end+0x3dd4a920>
ffffffffc02035ca:	00e5e663          	bltu	a1,a4,ffffffffc02035d6 <find_vma+0x22>
ffffffffc02035ce:	ff07b703          	ld	a4,-16(a5)
ffffffffc02035d2:	00e5ee63          	bltu	a1,a4,ffffffffc02035ee <find_vma+0x3a>
ffffffffc02035d6:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02035d8:	fef517e3          	bne	a0,a5,ffffffffc02035c6 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc02035dc:	4781                	li	a5,0
}
ffffffffc02035de:	853e                	mv	a0,a5
ffffffffc02035e0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02035e2:	6b98                	ld	a4,16(a5)
ffffffffc02035e4:	fce5fee3          	bgeu	a1,a4,ffffffffc02035c0 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc02035e8:	e91c                	sd	a5,16(a0)
}
ffffffffc02035ea:	853e                	mv	a0,a5
ffffffffc02035ec:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02035ee:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc02035f0:	e91c                	sd	a5,16(a0)
ffffffffc02035f2:	bfe5                	j	ffffffffc02035ea <find_vma+0x36>

ffffffffc02035f4 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02035f4:	6590                	ld	a2,8(a1)
ffffffffc02035f6:	0105b803          	ld	a6,16(a1)
{
ffffffffc02035fa:	1141                	addi	sp,sp,-16
ffffffffc02035fc:	e406                	sd	ra,8(sp)
ffffffffc02035fe:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203600:	01066763          	bltu	a2,a6,ffffffffc020360e <insert_vma_struct+0x1a>
ffffffffc0203604:	a8b9                	j	ffffffffc0203662 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203606:	fe87b703          	ld	a4,-24(a5)
ffffffffc020360a:	04e66763          	bltu	a2,a4,ffffffffc0203658 <insert_vma_struct+0x64>
ffffffffc020360e:	86be                	mv	a3,a5
ffffffffc0203610:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203612:	fef51ae3          	bne	a0,a5,ffffffffc0203606 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203616:	02a68463          	beq	a3,a0,ffffffffc020363e <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020361a:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020361e:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203622:	08e8f063          	bgeu	a7,a4,ffffffffc02036a2 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203626:	04e66e63          	bltu	a2,a4,ffffffffc0203682 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc020362a:	00f50a63          	beq	a0,a5,ffffffffc020363e <insert_vma_struct+0x4a>
ffffffffc020362e:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203632:	05076863          	bltu	a4,a6,ffffffffc0203682 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0203636:	ff07b603          	ld	a2,-16(a5)
ffffffffc020363a:	02c77263          	bgeu	a4,a2,ffffffffc020365e <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020363e:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203640:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203642:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203646:	e390                	sd	a2,0(a5)
ffffffffc0203648:	e690                	sd	a2,8(a3)
}
ffffffffc020364a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020364c:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020364e:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203650:	2705                	addiw	a4,a4,1
ffffffffc0203652:	d118                	sw	a4,32(a0)
}
ffffffffc0203654:	0141                	addi	sp,sp,16
ffffffffc0203656:	8082                	ret
    if (le_prev != list)
ffffffffc0203658:	fca691e3          	bne	a3,a0,ffffffffc020361a <insert_vma_struct+0x26>
ffffffffc020365c:	bfd9                	j	ffffffffc0203632 <insert_vma_struct+0x3e>
ffffffffc020365e:	f03ff0ef          	jal	ffffffffc0203560 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203662:	00003697          	auipc	a3,0x3
ffffffffc0203666:	74668693          	addi	a3,a3,1862 # ffffffffc0206da8 <etext+0x1500>
ffffffffc020366a:	00003617          	auipc	a2,0x3
ffffffffc020366e:	c1e60613          	addi	a2,a2,-994 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203672:	07a00593          	li	a1,122
ffffffffc0203676:	00003517          	auipc	a0,0x3
ffffffffc020367a:	72250513          	addi	a0,a0,1826 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc020367e:	dcdfc0ef          	jal	ffffffffc020044a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203682:	00003697          	auipc	a3,0x3
ffffffffc0203686:	76668693          	addi	a3,a3,1894 # ffffffffc0206de8 <etext+0x1540>
ffffffffc020368a:	00003617          	auipc	a2,0x3
ffffffffc020368e:	bfe60613          	addi	a2,a2,-1026 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203692:	07300593          	li	a1,115
ffffffffc0203696:	00003517          	auipc	a0,0x3
ffffffffc020369a:	70250513          	addi	a0,a0,1794 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc020369e:	dadfc0ef          	jal	ffffffffc020044a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036a2:	00003697          	auipc	a3,0x3
ffffffffc02036a6:	72668693          	addi	a3,a3,1830 # ffffffffc0206dc8 <etext+0x1520>
ffffffffc02036aa:	00003617          	auipc	a2,0x3
ffffffffc02036ae:	bde60613          	addi	a2,a2,-1058 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02036b2:	07200593          	li	a1,114
ffffffffc02036b6:	00003517          	auipc	a0,0x3
ffffffffc02036ba:	6e250513          	addi	a0,a0,1762 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc02036be:	d8dfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02036c2 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02036c2:	591c                	lw	a5,48(a0)
{
ffffffffc02036c4:	1141                	addi	sp,sp,-16
ffffffffc02036c6:	e406                	sd	ra,8(sp)
ffffffffc02036c8:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02036ca:	e78d                	bnez	a5,ffffffffc02036f4 <mm_destroy+0x32>
ffffffffc02036cc:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02036ce:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02036d0:	00a40c63          	beq	s0,a0,ffffffffc02036e8 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02036d4:	6118                	ld	a4,0(a0)
ffffffffc02036d6:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02036d8:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02036da:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02036dc:	e398                	sd	a4,0(a5)
ffffffffc02036de:	dc4fe0ef          	jal	ffffffffc0201ca2 <kfree>
    return listelm->next;
ffffffffc02036e2:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02036e4:	fea418e3          	bne	s0,a0,ffffffffc02036d4 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02036e8:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02036ea:	6402                	ld	s0,0(sp)
ffffffffc02036ec:	60a2                	ld	ra,8(sp)
ffffffffc02036ee:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02036f0:	db2fe06f          	j	ffffffffc0201ca2 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02036f4:	00003697          	auipc	a3,0x3
ffffffffc02036f8:	71468693          	addi	a3,a3,1812 # ffffffffc0206e08 <etext+0x1560>
ffffffffc02036fc:	00003617          	auipc	a2,0x3
ffffffffc0203700:	b8c60613          	addi	a2,a2,-1140 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203704:	09e00593          	li	a1,158
ffffffffc0203708:	00003517          	auipc	a0,0x3
ffffffffc020370c:	69050513          	addi	a0,a0,1680 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203710:	d3bfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203714 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203714:	6785                	lui	a5,0x1
ffffffffc0203716:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7f29>
ffffffffc0203718:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc020371a:	4785                	li	a5,1
{
ffffffffc020371c:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020371e:	962e                	add	a2,a2,a1
ffffffffc0203720:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc0203722:	07fe                	slli	a5,a5,0x1f
{
ffffffffc0203724:	f822                	sd	s0,48(sp)
ffffffffc0203726:	f426                	sd	s1,40(sp)
ffffffffc0203728:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020372c:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc0203730:	0785                	addi	a5,a5,1
ffffffffc0203732:	0084b633          	sltu	a2,s1,s0
ffffffffc0203736:	00f437b3          	sltu	a5,s0,a5
ffffffffc020373a:	00163613          	seqz	a2,a2
ffffffffc020373e:	0017b793          	seqz	a5,a5
{
ffffffffc0203742:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203744:	8fd1                	or	a5,a5,a2
ffffffffc0203746:	ebbd                	bnez	a5,ffffffffc02037bc <mm_map+0xa8>
ffffffffc0203748:	002007b7          	lui	a5,0x200
ffffffffc020374c:	06f4e863          	bltu	s1,a5,ffffffffc02037bc <mm_map+0xa8>
ffffffffc0203750:	f04a                	sd	s2,32(sp)
ffffffffc0203752:	ec4e                	sd	s3,24(sp)
ffffffffc0203754:	e852                	sd	s4,16(sp)
ffffffffc0203756:	892a                	mv	s2,a0
ffffffffc0203758:	89ba                	mv	s3,a4
ffffffffc020375a:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020375c:	c135                	beqz	a0,ffffffffc02037c0 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc020375e:	85a6                	mv	a1,s1
ffffffffc0203760:	e55ff0ef          	jal	ffffffffc02035b4 <find_vma>
ffffffffc0203764:	c501                	beqz	a0,ffffffffc020376c <mm_map+0x58>
ffffffffc0203766:	651c                	ld	a5,8(a0)
ffffffffc0203768:	0487e763          	bltu	a5,s0,ffffffffc02037b6 <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020376c:	03000513          	li	a0,48
ffffffffc0203770:	c8cfe0ef          	jal	ffffffffc0201bfc <kmalloc>
ffffffffc0203774:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203776:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203778:	c59d                	beqz	a1,ffffffffc02037a6 <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc020377a:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc020377c:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc020377e:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203782:	854a                	mv	a0,s2
ffffffffc0203784:	e42e                	sd	a1,8(sp)
ffffffffc0203786:	e6fff0ef          	jal	ffffffffc02035f4 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc020378a:	65a2                	ld	a1,8(sp)
ffffffffc020378c:	00098463          	beqz	s3,ffffffffc0203794 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203790:	00b9b023          	sd	a1,0(s3)
ffffffffc0203794:	7902                	ld	s2,32(sp)
ffffffffc0203796:	69e2                	ld	s3,24(sp)
ffffffffc0203798:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc020379a:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc020379c:	70e2                	ld	ra,56(sp)
ffffffffc020379e:	7442                	ld	s0,48(sp)
ffffffffc02037a0:	74a2                	ld	s1,40(sp)
ffffffffc02037a2:	6121                	addi	sp,sp,64
ffffffffc02037a4:	8082                	ret
ffffffffc02037a6:	70e2                	ld	ra,56(sp)
ffffffffc02037a8:	7442                	ld	s0,48(sp)
ffffffffc02037aa:	7902                	ld	s2,32(sp)
ffffffffc02037ac:	69e2                	ld	s3,24(sp)
ffffffffc02037ae:	6a42                	ld	s4,16(sp)
ffffffffc02037b0:	74a2                	ld	s1,40(sp)
ffffffffc02037b2:	6121                	addi	sp,sp,64
ffffffffc02037b4:	8082                	ret
ffffffffc02037b6:	7902                	ld	s2,32(sp)
ffffffffc02037b8:	69e2                	ld	s3,24(sp)
ffffffffc02037ba:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc02037bc:	5575                	li	a0,-3
ffffffffc02037be:	bff9                	j	ffffffffc020379c <mm_map+0x88>
    assert(mm != NULL);
ffffffffc02037c0:	00003697          	auipc	a3,0x3
ffffffffc02037c4:	66068693          	addi	a3,a3,1632 # ffffffffc0206e20 <etext+0x1578>
ffffffffc02037c8:	00003617          	auipc	a2,0x3
ffffffffc02037cc:	ac060613          	addi	a2,a2,-1344 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02037d0:	0b300593          	li	a1,179
ffffffffc02037d4:	00003517          	auipc	a0,0x3
ffffffffc02037d8:	5c450513          	addi	a0,a0,1476 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc02037dc:	c6ffc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02037e0 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02037e0:	7139                	addi	sp,sp,-64
ffffffffc02037e2:	fc06                	sd	ra,56(sp)
ffffffffc02037e4:	f822                	sd	s0,48(sp)
ffffffffc02037e6:	f426                	sd	s1,40(sp)
ffffffffc02037e8:	f04a                	sd	s2,32(sp)
ffffffffc02037ea:	ec4e                	sd	s3,24(sp)
ffffffffc02037ec:	e852                	sd	s4,16(sp)
ffffffffc02037ee:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02037f0:	c525                	beqz	a0,ffffffffc0203858 <dup_mmap+0x78>
ffffffffc02037f2:	892a                	mv	s2,a0
ffffffffc02037f4:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02037f6:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02037f8:	c1a5                	beqz	a1,ffffffffc0203858 <dup_mmap+0x78>
    return listelm->prev;
ffffffffc02037fa:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02037fc:	04848c63          	beq	s1,s0,ffffffffc0203854 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203800:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203804:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203808:	ff043a03          	ld	s4,-16(s0)
ffffffffc020380c:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203810:	becfe0ef          	jal	ffffffffc0201bfc <kmalloc>
    if (vma != NULL)
ffffffffc0203814:	c515                	beqz	a0,ffffffffc0203840 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203816:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203818:	01553423          	sd	s5,8(a0)
ffffffffc020381c:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203820:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc0203824:	854a                	mv	a0,s2
ffffffffc0203826:	dcfff0ef          	jal	ffffffffc02035f4 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc020382a:	ff043683          	ld	a3,-16(s0)
ffffffffc020382e:	fe843603          	ld	a2,-24(s0)
ffffffffc0203832:	6c8c                	ld	a1,24(s1)
ffffffffc0203834:	01893503          	ld	a0,24(s2)
ffffffffc0203838:	4701                	li	a4,0
ffffffffc020383a:	cc7fe0ef          	jal	ffffffffc0202500 <copy_range>
ffffffffc020383e:	dd55                	beqz	a0,ffffffffc02037fa <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc0203840:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203842:	70e2                	ld	ra,56(sp)
ffffffffc0203844:	7442                	ld	s0,48(sp)
ffffffffc0203846:	74a2                	ld	s1,40(sp)
ffffffffc0203848:	7902                	ld	s2,32(sp)
ffffffffc020384a:	69e2                	ld	s3,24(sp)
ffffffffc020384c:	6a42                	ld	s4,16(sp)
ffffffffc020384e:	6aa2                	ld	s5,8(sp)
ffffffffc0203850:	6121                	addi	sp,sp,64
ffffffffc0203852:	8082                	ret
    return 0;
ffffffffc0203854:	4501                	li	a0,0
ffffffffc0203856:	b7f5                	j	ffffffffc0203842 <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc0203858:	00003697          	auipc	a3,0x3
ffffffffc020385c:	5d868693          	addi	a3,a3,1496 # ffffffffc0206e30 <etext+0x1588>
ffffffffc0203860:	00003617          	auipc	a2,0x3
ffffffffc0203864:	a2860613          	addi	a2,a2,-1496 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203868:	0cf00593          	li	a1,207
ffffffffc020386c:	00003517          	auipc	a0,0x3
ffffffffc0203870:	52c50513          	addi	a0,a0,1324 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203874:	bd7fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203878 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203878:	1101                	addi	sp,sp,-32
ffffffffc020387a:	ec06                	sd	ra,24(sp)
ffffffffc020387c:	e822                	sd	s0,16(sp)
ffffffffc020387e:	e426                	sd	s1,8(sp)
ffffffffc0203880:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203882:	c531                	beqz	a0,ffffffffc02038ce <exit_mmap+0x56>
ffffffffc0203884:	591c                	lw	a5,48(a0)
ffffffffc0203886:	84aa                	mv	s1,a0
ffffffffc0203888:	e3b9                	bnez	a5,ffffffffc02038ce <exit_mmap+0x56>
    return listelm->next;
ffffffffc020388a:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc020388c:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203890:	02850663          	beq	a0,s0,ffffffffc02038bc <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203894:	ff043603          	ld	a2,-16(s0)
ffffffffc0203898:	fe843583          	ld	a1,-24(s0)
ffffffffc020389c:	854a                	mv	a0,s2
ffffffffc020389e:	87bfe0ef          	jal	ffffffffc0202118 <unmap_range>
ffffffffc02038a2:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038a4:	fe8498e3          	bne	s1,s0,ffffffffc0203894 <exit_mmap+0x1c>
ffffffffc02038a8:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02038aa:	00848c63          	beq	s1,s0,ffffffffc02038c2 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038ae:	ff043603          	ld	a2,-16(s0)
ffffffffc02038b2:	fe843583          	ld	a1,-24(s0)
ffffffffc02038b6:	854a                	mv	a0,s2
ffffffffc02038b8:	995fe0ef          	jal	ffffffffc020224c <exit_range>
ffffffffc02038bc:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038be:	fe8498e3          	bne	s1,s0,ffffffffc02038ae <exit_mmap+0x36>
    }
}
ffffffffc02038c2:	60e2                	ld	ra,24(sp)
ffffffffc02038c4:	6442                	ld	s0,16(sp)
ffffffffc02038c6:	64a2                	ld	s1,8(sp)
ffffffffc02038c8:	6902                	ld	s2,0(sp)
ffffffffc02038ca:	6105                	addi	sp,sp,32
ffffffffc02038cc:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02038ce:	00003697          	auipc	a3,0x3
ffffffffc02038d2:	58268693          	addi	a3,a3,1410 # ffffffffc0206e50 <etext+0x15a8>
ffffffffc02038d6:	00003617          	auipc	a2,0x3
ffffffffc02038da:	9b260613          	addi	a2,a2,-1614 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02038de:	0e800593          	li	a1,232
ffffffffc02038e2:	00003517          	auipc	a0,0x3
ffffffffc02038e6:	4b650513          	addi	a0,a0,1206 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc02038ea:	b61fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02038ee <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02038ee:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038f0:	04000513          	li	a0,64
{
ffffffffc02038f4:	f406                	sd	ra,40(sp)
ffffffffc02038f6:	f022                	sd	s0,32(sp)
ffffffffc02038f8:	ec26                	sd	s1,24(sp)
ffffffffc02038fa:	e84a                	sd	s2,16(sp)
ffffffffc02038fc:	e44e                	sd	s3,8(sp)
ffffffffc02038fe:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203900:	afcfe0ef          	jal	ffffffffc0201bfc <kmalloc>
    if (mm != NULL)
ffffffffc0203904:	16050c63          	beqz	a0,ffffffffc0203a7c <vmm_init+0x18e>
ffffffffc0203908:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc020390a:	e508                	sd	a0,8(a0)
ffffffffc020390c:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020390e:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203912:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203916:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020391a:	02053423          	sd	zero,40(a0)
ffffffffc020391e:	02052823          	sw	zero,48(a0)
ffffffffc0203922:	02053c23          	sd	zero,56(a0)
ffffffffc0203926:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020392a:	03000513          	li	a0,48
ffffffffc020392e:	acefe0ef          	jal	ffffffffc0201bfc <kmalloc>
    if (vma != NULL)
ffffffffc0203932:	12050563          	beqz	a0,ffffffffc0203a5c <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203936:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc020393a:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc020393c:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203940:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203942:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203944:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203946:	8522                	mv	a0,s0
ffffffffc0203948:	cadff0ef          	jal	ffffffffc02035f4 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc020394c:	fcf9                	bnez	s1,ffffffffc020392a <vmm_init+0x3c>
ffffffffc020394e:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203952:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203956:	03000513          	li	a0,48
ffffffffc020395a:	aa2fe0ef          	jal	ffffffffc0201bfc <kmalloc>
    if (vma != NULL)
ffffffffc020395e:	12050f63          	beqz	a0,ffffffffc0203a9c <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203962:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203966:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203968:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc020396c:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020396e:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203970:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203972:	8522                	mv	a0,s0
ffffffffc0203974:	c81ff0ef          	jal	ffffffffc02035f4 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203978:	fd249fe3          	bne	s1,s2,ffffffffc0203956 <vmm_init+0x68>
    return listelm->next;
ffffffffc020397c:	641c                	ld	a5,8(s0)
ffffffffc020397e:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203980:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203984:	1ef40c63          	beq	s0,a5,ffffffffc0203b7c <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203988:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f4aa8>
ffffffffc020398c:	ffe70693          	addi	a3,a4,-2
ffffffffc0203990:	12d61663          	bne	a2,a3,ffffffffc0203abc <vmm_init+0x1ce>
ffffffffc0203994:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203998:	12e69263          	bne	a3,a4,ffffffffc0203abc <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc020399c:	0715                	addi	a4,a4,5
ffffffffc020399e:	679c                	ld	a5,8(a5)
ffffffffc02039a0:	feb712e3          	bne	a4,a1,ffffffffc0203984 <vmm_init+0x96>
ffffffffc02039a4:	491d                	li	s2,7
ffffffffc02039a6:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02039a8:	85a6                	mv	a1,s1
ffffffffc02039aa:	8522                	mv	a0,s0
ffffffffc02039ac:	c09ff0ef          	jal	ffffffffc02035b4 <find_vma>
ffffffffc02039b0:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc02039b2:	20050563          	beqz	a0,ffffffffc0203bbc <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc02039b6:	00148593          	addi	a1,s1,1
ffffffffc02039ba:	8522                	mv	a0,s0
ffffffffc02039bc:	bf9ff0ef          	jal	ffffffffc02035b4 <find_vma>
ffffffffc02039c0:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc02039c2:	1c050d63          	beqz	a0,ffffffffc0203b9c <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc02039c6:	85ca                	mv	a1,s2
ffffffffc02039c8:	8522                	mv	a0,s0
ffffffffc02039ca:	bebff0ef          	jal	ffffffffc02035b4 <find_vma>
        assert(vma3 == NULL);
ffffffffc02039ce:	18051763          	bnez	a0,ffffffffc0203b5c <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc02039d2:	00348593          	addi	a1,s1,3
ffffffffc02039d6:	8522                	mv	a0,s0
ffffffffc02039d8:	bddff0ef          	jal	ffffffffc02035b4 <find_vma>
        assert(vma4 == NULL);
ffffffffc02039dc:	16051063          	bnez	a0,ffffffffc0203b3c <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc02039e0:	00448593          	addi	a1,s1,4
ffffffffc02039e4:	8522                	mv	a0,s0
ffffffffc02039e6:	bcfff0ef          	jal	ffffffffc02035b4 <find_vma>
        assert(vma5 == NULL);
ffffffffc02039ea:	12051963          	bnez	a0,ffffffffc0203b1c <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02039ee:	008a3783          	ld	a5,8(s4)
ffffffffc02039f2:	10979563          	bne	a5,s1,ffffffffc0203afc <vmm_init+0x20e>
ffffffffc02039f6:	010a3783          	ld	a5,16(s4)
ffffffffc02039fa:	11279163          	bne	a5,s2,ffffffffc0203afc <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02039fe:	0089b783          	ld	a5,8(s3)
ffffffffc0203a02:	0c979d63          	bne	a5,s1,ffffffffc0203adc <vmm_init+0x1ee>
ffffffffc0203a06:	0109b783          	ld	a5,16(s3)
ffffffffc0203a0a:	0d279963          	bne	a5,s2,ffffffffc0203adc <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a0e:	0495                	addi	s1,s1,5
ffffffffc0203a10:	1f900793          	li	a5,505
ffffffffc0203a14:	0915                	addi	s2,s2,5
ffffffffc0203a16:	f8f499e3          	bne	s1,a5,ffffffffc02039a8 <vmm_init+0xba>
ffffffffc0203a1a:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203a1c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203a1e:	85a6                	mv	a1,s1
ffffffffc0203a20:	8522                	mv	a0,s0
ffffffffc0203a22:	b93ff0ef          	jal	ffffffffc02035b4 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203a26:	1a051b63          	bnez	a0,ffffffffc0203bdc <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203a2a:	14fd                	addi	s1,s1,-1
ffffffffc0203a2c:	ff2499e3          	bne	s1,s2,ffffffffc0203a1e <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203a30:	8522                	mv	a0,s0
ffffffffc0203a32:	c91ff0ef          	jal	ffffffffc02036c2 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203a36:	00003517          	auipc	a0,0x3
ffffffffc0203a3a:	58a50513          	addi	a0,a0,1418 # ffffffffc0206fc0 <etext+0x1718>
ffffffffc0203a3e:	f5afc0ef          	jal	ffffffffc0200198 <cprintf>
}
ffffffffc0203a42:	7402                	ld	s0,32(sp)
ffffffffc0203a44:	70a2                	ld	ra,40(sp)
ffffffffc0203a46:	64e2                	ld	s1,24(sp)
ffffffffc0203a48:	6942                	ld	s2,16(sp)
ffffffffc0203a4a:	69a2                	ld	s3,8(sp)
ffffffffc0203a4c:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a4e:	00003517          	auipc	a0,0x3
ffffffffc0203a52:	59250513          	addi	a0,a0,1426 # ffffffffc0206fe0 <etext+0x1738>
}
ffffffffc0203a56:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a58:	f40fc06f          	j	ffffffffc0200198 <cprintf>
        assert(vma != NULL);
ffffffffc0203a5c:	00003697          	auipc	a3,0x3
ffffffffc0203a60:	41468693          	addi	a3,a3,1044 # ffffffffc0206e70 <etext+0x15c8>
ffffffffc0203a64:	00003617          	auipc	a2,0x3
ffffffffc0203a68:	82460613          	addi	a2,a2,-2012 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203a6c:	12c00593          	li	a1,300
ffffffffc0203a70:	00003517          	auipc	a0,0x3
ffffffffc0203a74:	32850513          	addi	a0,a0,808 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203a78:	9d3fc0ef          	jal	ffffffffc020044a <__panic>
    assert(mm != NULL);
ffffffffc0203a7c:	00003697          	auipc	a3,0x3
ffffffffc0203a80:	3a468693          	addi	a3,a3,932 # ffffffffc0206e20 <etext+0x1578>
ffffffffc0203a84:	00003617          	auipc	a2,0x3
ffffffffc0203a88:	80460613          	addi	a2,a2,-2044 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203a8c:	12400593          	li	a1,292
ffffffffc0203a90:	00003517          	auipc	a0,0x3
ffffffffc0203a94:	30850513          	addi	a0,a0,776 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203a98:	9b3fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma != NULL);
ffffffffc0203a9c:	00003697          	auipc	a3,0x3
ffffffffc0203aa0:	3d468693          	addi	a3,a3,980 # ffffffffc0206e70 <etext+0x15c8>
ffffffffc0203aa4:	00002617          	auipc	a2,0x2
ffffffffc0203aa8:	7e460613          	addi	a2,a2,2020 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203aac:	13300593          	li	a1,307
ffffffffc0203ab0:	00003517          	auipc	a0,0x3
ffffffffc0203ab4:	2e850513          	addi	a0,a0,744 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203ab8:	993fc0ef          	jal	ffffffffc020044a <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203abc:	00003697          	auipc	a3,0x3
ffffffffc0203ac0:	3dc68693          	addi	a3,a3,988 # ffffffffc0206e98 <etext+0x15f0>
ffffffffc0203ac4:	00002617          	auipc	a2,0x2
ffffffffc0203ac8:	7c460613          	addi	a2,a2,1988 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203acc:	13d00593          	li	a1,317
ffffffffc0203ad0:	00003517          	auipc	a0,0x3
ffffffffc0203ad4:	2c850513          	addi	a0,a0,712 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203ad8:	973fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203adc:	00003697          	auipc	a3,0x3
ffffffffc0203ae0:	47468693          	addi	a3,a3,1140 # ffffffffc0206f50 <etext+0x16a8>
ffffffffc0203ae4:	00002617          	auipc	a2,0x2
ffffffffc0203ae8:	7a460613          	addi	a2,a2,1956 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203aec:	14f00593          	li	a1,335
ffffffffc0203af0:	00003517          	auipc	a0,0x3
ffffffffc0203af4:	2a850513          	addi	a0,a0,680 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203af8:	953fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203afc:	00003697          	auipc	a3,0x3
ffffffffc0203b00:	42468693          	addi	a3,a3,1060 # ffffffffc0206f20 <etext+0x1678>
ffffffffc0203b04:	00002617          	auipc	a2,0x2
ffffffffc0203b08:	78460613          	addi	a2,a2,1924 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203b0c:	14e00593          	li	a1,334
ffffffffc0203b10:	00003517          	auipc	a0,0x3
ffffffffc0203b14:	28850513          	addi	a0,a0,648 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203b18:	933fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma5 == NULL);
ffffffffc0203b1c:	00003697          	auipc	a3,0x3
ffffffffc0203b20:	3f468693          	addi	a3,a3,1012 # ffffffffc0206f10 <etext+0x1668>
ffffffffc0203b24:	00002617          	auipc	a2,0x2
ffffffffc0203b28:	76460613          	addi	a2,a2,1892 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203b2c:	14c00593          	li	a1,332
ffffffffc0203b30:	00003517          	auipc	a0,0x3
ffffffffc0203b34:	26850513          	addi	a0,a0,616 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203b38:	913fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma4 == NULL);
ffffffffc0203b3c:	00003697          	auipc	a3,0x3
ffffffffc0203b40:	3c468693          	addi	a3,a3,964 # ffffffffc0206f00 <etext+0x1658>
ffffffffc0203b44:	00002617          	auipc	a2,0x2
ffffffffc0203b48:	74460613          	addi	a2,a2,1860 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203b4c:	14a00593          	li	a1,330
ffffffffc0203b50:	00003517          	auipc	a0,0x3
ffffffffc0203b54:	24850513          	addi	a0,a0,584 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203b58:	8f3fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma3 == NULL);
ffffffffc0203b5c:	00003697          	auipc	a3,0x3
ffffffffc0203b60:	39468693          	addi	a3,a3,916 # ffffffffc0206ef0 <etext+0x1648>
ffffffffc0203b64:	00002617          	auipc	a2,0x2
ffffffffc0203b68:	72460613          	addi	a2,a2,1828 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203b6c:	14800593          	li	a1,328
ffffffffc0203b70:	00003517          	auipc	a0,0x3
ffffffffc0203b74:	22850513          	addi	a0,a0,552 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203b78:	8d3fc0ef          	jal	ffffffffc020044a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203b7c:	00003697          	auipc	a3,0x3
ffffffffc0203b80:	30468693          	addi	a3,a3,772 # ffffffffc0206e80 <etext+0x15d8>
ffffffffc0203b84:	00002617          	auipc	a2,0x2
ffffffffc0203b88:	70460613          	addi	a2,a2,1796 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203b8c:	13b00593          	li	a1,315
ffffffffc0203b90:	00003517          	auipc	a0,0x3
ffffffffc0203b94:	20850513          	addi	a0,a0,520 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203b98:	8b3fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma2 != NULL);
ffffffffc0203b9c:	00003697          	auipc	a3,0x3
ffffffffc0203ba0:	34468693          	addi	a3,a3,836 # ffffffffc0206ee0 <etext+0x1638>
ffffffffc0203ba4:	00002617          	auipc	a2,0x2
ffffffffc0203ba8:	6e460613          	addi	a2,a2,1764 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203bac:	14600593          	li	a1,326
ffffffffc0203bb0:	00003517          	auipc	a0,0x3
ffffffffc0203bb4:	1e850513          	addi	a0,a0,488 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203bb8:	893fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma1 != NULL);
ffffffffc0203bbc:	00003697          	auipc	a3,0x3
ffffffffc0203bc0:	31468693          	addi	a3,a3,788 # ffffffffc0206ed0 <etext+0x1628>
ffffffffc0203bc4:	00002617          	auipc	a2,0x2
ffffffffc0203bc8:	6c460613          	addi	a2,a2,1732 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203bcc:	14400593          	li	a1,324
ffffffffc0203bd0:	00003517          	auipc	a0,0x3
ffffffffc0203bd4:	1c850513          	addi	a0,a0,456 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203bd8:	873fc0ef          	jal	ffffffffc020044a <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203bdc:	6914                	ld	a3,16(a0)
ffffffffc0203bde:	6510                	ld	a2,8(a0)
ffffffffc0203be0:	0004859b          	sext.w	a1,s1
ffffffffc0203be4:	00003517          	auipc	a0,0x3
ffffffffc0203be8:	39c50513          	addi	a0,a0,924 # ffffffffc0206f80 <etext+0x16d8>
ffffffffc0203bec:	dacfc0ef          	jal	ffffffffc0200198 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203bf0:	00003697          	auipc	a3,0x3
ffffffffc0203bf4:	3b868693          	addi	a3,a3,952 # ffffffffc0206fa8 <etext+0x1700>
ffffffffc0203bf8:	00002617          	auipc	a2,0x2
ffffffffc0203bfc:	69060613          	addi	a2,a2,1680 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0203c00:	15900593          	li	a1,345
ffffffffc0203c04:	00003517          	auipc	a0,0x3
ffffffffc0203c08:	19450513          	addi	a0,a0,404 # ffffffffc0206d98 <etext+0x14f0>
ffffffffc0203c0c:	83ffc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203c10 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203c10:	7179                	addi	sp,sp,-48
ffffffffc0203c12:	f022                	sd	s0,32(sp)
ffffffffc0203c14:	f406                	sd	ra,40(sp)
ffffffffc0203c16:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203c18:	c52d                	beqz	a0,ffffffffc0203c82 <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203c1a:	002007b7          	lui	a5,0x200
ffffffffc0203c1e:	04f5ed63          	bltu	a1,a5,ffffffffc0203c78 <user_mem_check+0x68>
ffffffffc0203c22:	ec26                	sd	s1,24(sp)
ffffffffc0203c24:	00c584b3          	add	s1,a1,a2
ffffffffc0203c28:	0695ff63          	bgeu	a1,s1,ffffffffc0203ca6 <user_mem_check+0x96>
ffffffffc0203c2c:	4785                	li	a5,1
ffffffffc0203c2e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203c30:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_matrix_out_size+0x1f4ac1>
ffffffffc0203c32:	06f4fa63          	bgeu	s1,a5,ffffffffc0203ca6 <user_mem_check+0x96>
ffffffffc0203c36:	e84a                	sd	s2,16(sp)
ffffffffc0203c38:	e44e                	sd	s3,8(sp)
ffffffffc0203c3a:	8936                	mv	s2,a3
ffffffffc0203c3c:	89aa                	mv	s3,a0
ffffffffc0203c3e:	a829                	j	ffffffffc0203c58 <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c40:	6685                	lui	a3,0x1
ffffffffc0203c42:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c44:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c48:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c4a:	c685                	beqz	a3,ffffffffc0203c72 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c4c:	c399                	beqz	a5,ffffffffc0203c52 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c4e:	02e46263          	bltu	s0,a4,ffffffffc0203c72 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203c52:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203c54:	04947b63          	bgeu	s0,s1,ffffffffc0203caa <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203c58:	85a2                	mv	a1,s0
ffffffffc0203c5a:	854e                	mv	a0,s3
ffffffffc0203c5c:	959ff0ef          	jal	ffffffffc02035b4 <find_vma>
ffffffffc0203c60:	c909                	beqz	a0,ffffffffc0203c72 <user_mem_check+0x62>
ffffffffc0203c62:	6518                	ld	a4,8(a0)
ffffffffc0203c64:	00e46763          	bltu	s0,a4,ffffffffc0203c72 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c68:	4d1c                	lw	a5,24(a0)
ffffffffc0203c6a:	fc091be3          	bnez	s2,ffffffffc0203c40 <user_mem_check+0x30>
ffffffffc0203c6e:	8b85                	andi	a5,a5,1
ffffffffc0203c70:	f3ed                	bnez	a5,ffffffffc0203c52 <user_mem_check+0x42>
ffffffffc0203c72:	64e2                	ld	s1,24(sp)
ffffffffc0203c74:	6942                	ld	s2,16(sp)
ffffffffc0203c76:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203c78:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203c7a:	70a2                	ld	ra,40(sp)
ffffffffc0203c7c:	7402                	ld	s0,32(sp)
ffffffffc0203c7e:	6145                	addi	sp,sp,48
ffffffffc0203c80:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203c82:	c02007b7          	lui	a5,0xc0200
ffffffffc0203c86:	fef5eae3          	bltu	a1,a5,ffffffffc0203c7a <user_mem_check+0x6a>
ffffffffc0203c8a:	c80007b7          	lui	a5,0xc8000
ffffffffc0203c8e:	962e                	add	a2,a2,a1
ffffffffc0203c90:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d4a939>
ffffffffc0203c92:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203c96:	00f63633          	sltu	a2,a2,a5
}
ffffffffc0203c9a:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203c9c:	00867533          	and	a0,a2,s0
}
ffffffffc0203ca0:	7402                	ld	s0,32(sp)
ffffffffc0203ca2:	6145                	addi	sp,sp,48
ffffffffc0203ca4:	8082                	ret
ffffffffc0203ca6:	64e2                	ld	s1,24(sp)
ffffffffc0203ca8:	bfc1                	j	ffffffffc0203c78 <user_mem_check+0x68>
ffffffffc0203caa:	64e2                	ld	s1,24(sp)
ffffffffc0203cac:	6942                	ld	s2,16(sp)
ffffffffc0203cae:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203cb0:	4505                	li	a0,1
ffffffffc0203cb2:	b7e1                	j	ffffffffc0203c7a <user_mem_check+0x6a>

ffffffffc0203cb4 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203cb4:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203cb6:	9402                	jalr	s0

	jal do_exit
ffffffffc0203cb8:	5e8000ef          	jal	ffffffffc02042a0 <do_exit>

ffffffffc0203cbc <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203cbc:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203cbe:	14800513          	li	a0,328
{
ffffffffc0203cc2:	e022                	sd	s0,0(sp)
ffffffffc0203cc4:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203cc6:	f37fd0ef          	jal	ffffffffc0201bfc <kmalloc>
ffffffffc0203cca:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203ccc:	c141                	beqz	a0,ffffffffc0203d4c <alloc_proc+0x90>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc0203cce:	57fd                	li	a5,-1
ffffffffc0203cd0:	1782                	slli	a5,a5,0x20
ffffffffc0203cd2:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0203cd4:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203cd8:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203cdc:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203ce0:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203ce4:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203ce8:	07000613          	li	a2,112
ffffffffc0203cec:	4581                	li	a1,0
ffffffffc0203cee:	03050513          	addi	a0,a0,48
ffffffffc0203cf2:	38d010ef          	jal	ffffffffc020587e <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203cf6:	000b2797          	auipc	a5,0xb2
ffffffffc0203cfa:	97a7b783          	ld	a5,-1670(a5) # ffffffffc02b5670 <boot_pgdir_pa>
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203cfe:	4641                	li	a2,16
ffffffffc0203d00:	4581                	li	a1,0
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203d02:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203d04:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203d08:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203d0c:	0b440513          	addi	a0,s0,180
ffffffffc0203d10:	36f010ef          	jal	ffffffffc020587e <memset>
         *       skew_heap_entry_t lab6_run_pool;            // entry in the run pool (lab6 stride)
         *       uint32_t lab6_stride;                       // stride value (lab6 stride)
         *       uint32_t lab6_priority;                     // priority value (lab6 stride)
         */
        proc->rq = NULL;
        list_init(&proc->run_link);
ffffffffc0203d14:	11040793          	addi	a5,s0,272
    elm->prev = elm->next = elm;
ffffffffc0203d18:	10f43c23          	sd	a5,280(s0)
ffffffffc0203d1c:	10f43823          	sd	a5,272(s0)
        proc->exit_code = 0;
ffffffffc0203d20:	0e043423          	sd	zero,232(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203d24:	0e043823          	sd	zero,240(s0)
ffffffffc0203d28:	0e043c23          	sd	zero,248(s0)
ffffffffc0203d2c:	10043023          	sd	zero,256(s0)
        proc->rq = NULL;
ffffffffc0203d30:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;
ffffffffc0203d34:	12042023          	sw	zero,288(s0)
        memset(&proc->lab6_run_pool, 0, sizeof(proc->lab6_run_pool));
ffffffffc0203d38:	12840513          	addi	a0,s0,296
ffffffffc0203d3c:	4661                	li	a2,24
ffffffffc0203d3e:	4581                	li	a1,0
ffffffffc0203d40:	33f010ef          	jal	ffffffffc020587e <memset>
        proc->lab6_stride = 0;
ffffffffc0203d44:	4785                	li	a5,1
ffffffffc0203d46:	1782                	slli	a5,a5,0x20
ffffffffc0203d48:	14f43023          	sd	a5,320(s0)
        proc->lab6_priority = 1;
    }
    return proc;
}
ffffffffc0203d4c:	60a2                	ld	ra,8(sp)
ffffffffc0203d4e:	8522                	mv	a0,s0
ffffffffc0203d50:	6402                	ld	s0,0(sp)
ffffffffc0203d52:	0141                	addi	sp,sp,16
ffffffffc0203d54:	8082                	ret

ffffffffc0203d56 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203d56:	000b2797          	auipc	a5,0xb2
ffffffffc0203d5a:	94a7b783          	ld	a5,-1718(a5) # ffffffffc02b56a0 <current>
ffffffffc0203d5e:	73c8                	ld	a0,160(a5)
ffffffffc0203d60:	92afd06f          	j	ffffffffc0200e8a <forkrets>

ffffffffc0203d64 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203d64:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203d66:	1141                	addi	sp,sp,-16
ffffffffc0203d68:	e406                	sd	ra,8(sp)
ffffffffc0203d6a:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d6e:	02f6ee63          	bltu	a3,a5,ffffffffc0203daa <put_pgdir+0x46>
ffffffffc0203d72:	000b2717          	auipc	a4,0xb2
ffffffffc0203d76:	90e73703          	ld	a4,-1778(a4) # ffffffffc02b5680 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203d7a:	000b2797          	auipc	a5,0xb2
ffffffffc0203d7e:	90e7b783          	ld	a5,-1778(a5) # ffffffffc02b5688 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203d82:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203d84:	82b1                	srli	a3,a3,0xc
ffffffffc0203d86:	02f6fe63          	bgeu	a3,a5,ffffffffc0203dc2 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203d8a:	00004797          	auipc	a5,0x4
ffffffffc0203d8e:	38e7b783          	ld	a5,910(a5) # ffffffffc0208118 <nbase>
ffffffffc0203d92:	000b2517          	auipc	a0,0xb2
ffffffffc0203d96:	8fe53503          	ld	a0,-1794(a0) # ffffffffc02b5690 <pages>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203d9a:	60a2                	ld	ra,8(sp)
ffffffffc0203d9c:	8e9d                	sub	a3,a3,a5
ffffffffc0203d9e:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203da0:	4585                	li	a1,1
ffffffffc0203da2:	9536                	add	a0,a0,a3
}
ffffffffc0203da4:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203da6:	852fe06f          	j	ffffffffc0201df8 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203daa:	00003617          	auipc	a2,0x3
ffffffffc0203dae:	93660613          	addi	a2,a2,-1738 # ffffffffc02066e0 <etext+0xe38>
ffffffffc0203db2:	07700593          	li	a1,119
ffffffffc0203db6:	00003517          	auipc	a0,0x3
ffffffffc0203dba:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0203dbe:	e8cfc0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203dc2:	00003617          	auipc	a2,0x3
ffffffffc0203dc6:	94660613          	addi	a2,a2,-1722 # ffffffffc0206708 <etext+0xe60>
ffffffffc0203dca:	06900593          	li	a1,105
ffffffffc0203dce:	00003517          	auipc	a0,0x3
ffffffffc0203dd2:	89250513          	addi	a0,a0,-1902 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0203dd6:	e74fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203dda <proc_run>:
    if (proc != current)
ffffffffc0203dda:	000b2697          	auipc	a3,0xb2
ffffffffc0203dde:	8c668693          	addi	a3,a3,-1850 # ffffffffc02b56a0 <current>
ffffffffc0203de2:	6298                	ld	a4,0(a3)
ffffffffc0203de4:	06a70363          	beq	a4,a0,ffffffffc0203e4a <proc_run+0x70>
{
ffffffffc0203de8:	1101                	addi	sp,sp,-32
ffffffffc0203dea:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203dec:	100027f3          	csrr	a5,sstatus
ffffffffc0203df0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203df2:	4801                	li	a6,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203df4:	eb9d                	bnez	a5,ffffffffc0203e2a <proc_run+0x50>
        proc->runs++; // 更新进程相关状态
ffffffffc0203df6:	4510                	lw	a2,8(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203df8:	755c                	ld	a5,168(a0)
        current=proc; // 切换进程
ffffffffc0203dfa:	e288                	sd	a0,0(a3)
ffffffffc0203dfc:	56fd                	li	a3,-1
        proc->runs++; // 更新进程相关状态
ffffffffc0203dfe:	2605                	addiw	a2,a2,1
ffffffffc0203e00:	16fe                	slli	a3,a3,0x3f
ffffffffc0203e02:	83b1                	srli	a5,a5,0xc
ffffffffc0203e04:	e442                	sd	a6,8(sp)
        current->need_resched = 0; // 不需要调度
ffffffffc0203e06:	00053c23          	sd	zero,24(a0)
        proc->runs++; // 更新进程相关状态
ffffffffc0203e0a:	c510                	sw	a2,8(a0)
ffffffffc0203e0c:	8fd5                	or	a5,a5,a3
ffffffffc0203e0e:	18079073          	csrw	satp,a5
        switch_to(&old->context,&proc->context); // 上下文切换
ffffffffc0203e12:	03050593          	addi	a1,a0,48
ffffffffc0203e16:	03070513          	addi	a0,a4,48
ffffffffc0203e1a:	1a6010ef          	jal	ffffffffc0204fc0 <switch_to>
    if (flag)
ffffffffc0203e1e:	6822                	ld	a6,8(sp)
ffffffffc0203e20:	02081163          	bnez	a6,ffffffffc0203e42 <proc_run+0x68>
}
ffffffffc0203e24:	60e2                	ld	ra,24(sp)
ffffffffc0203e26:	6105                	addi	sp,sp,32
ffffffffc0203e28:	8082                	ret
ffffffffc0203e2a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203e2c:	ad3fc0ef          	jal	ffffffffc02008fe <intr_disable>
        if (proc == current) {
ffffffffc0203e30:	000b2697          	auipc	a3,0xb2
ffffffffc0203e34:	87068693          	addi	a3,a3,-1936 # ffffffffc02b56a0 <current>
ffffffffc0203e38:	6298                	ld	a4,0(a3)
ffffffffc0203e3a:	6522                	ld	a0,8(sp)
        return 1;
ffffffffc0203e3c:	4805                	li	a6,1
ffffffffc0203e3e:	fae51ce3          	bne	a0,a4,ffffffffc0203df6 <proc_run+0x1c>
}
ffffffffc0203e42:	60e2                	ld	ra,24(sp)
ffffffffc0203e44:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203e46:	ab3fc06f          	j	ffffffffc02008f8 <intr_enable>
ffffffffc0203e4a:	8082                	ret

ffffffffc0203e4c <do_fork>:
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e4c:	000b2797          	auipc	a5,0xb2
ffffffffc0203e50:	84c7a783          	lw	a5,-1972(a5) # ffffffffc02b5698 <nr_process>
{
ffffffffc0203e54:	7159                	addi	sp,sp,-112
ffffffffc0203e56:	e4ce                	sd	s3,72(sp)
ffffffffc0203e58:	f486                	sd	ra,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e5a:	6985                	lui	s3,0x1
ffffffffc0203e5c:	3737db63          	bge	a5,s3,ffffffffc02041d2 <do_fork+0x386>
ffffffffc0203e60:	f0a2                	sd	s0,96(sp)
ffffffffc0203e62:	eca6                	sd	s1,88(sp)
ffffffffc0203e64:	e8ca                	sd	s2,80(sp)
ffffffffc0203e66:	e86a                	sd	s10,16(sp)
ffffffffc0203e68:	892e                	mv	s2,a1
ffffffffc0203e6a:	84b2                	mv	s1,a2
ffffffffc0203e6c:	8d2a                	mv	s10,a0
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
    // 1.创建进程结构体 
    if ((proc = alloc_proc()) == NULL)
ffffffffc0203e6e:	e4fff0ef          	jal	ffffffffc0203cbc <alloc_proc>
ffffffffc0203e72:	842a                	mv	s0,a0
ffffffffc0203e74:	2e050c63          	beqz	a0,ffffffffc020416c <do_fork+0x320>
ffffffffc0203e78:	f45e                	sd	s7,40(sp)
    {
        goto fork_out;
    }
    // 设置父进程
    proc->parent = current;
ffffffffc0203e7a:	000b2b97          	auipc	s7,0xb2
ffffffffc0203e7e:	826b8b93          	addi	s7,s7,-2010 # ffffffffc02b56a0 <current>
ffffffffc0203e82:	000bb783          	ld	a5,0(s7)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203e86:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0203e88:	f01c                	sd	a5,32(s0)
    current->wait_state = 0; // 确保父进程的wait_state为0 //////////+++
ffffffffc0203e8a:	0e07a623          	sw	zero,236(a5)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203e8e:	f31fd0ef          	jal	ffffffffc0201dbe <alloc_pages>
    if (page != NULL)
ffffffffc0203e92:	2c050963          	beqz	a0,ffffffffc0204164 <do_fork+0x318>
ffffffffc0203e96:	e0d2                	sd	s4,64(sp)
    return page - pages + nbase;
ffffffffc0203e98:	000b1a17          	auipc	s4,0xb1
ffffffffc0203e9c:	7f8a0a13          	addi	s4,s4,2040 # ffffffffc02b5690 <pages>
ffffffffc0203ea0:	000a3783          	ld	a5,0(s4)
ffffffffc0203ea4:	fc56                	sd	s5,56(sp)
ffffffffc0203ea6:	00004a97          	auipc	s5,0x4
ffffffffc0203eaa:	272a8a93          	addi	s5,s5,626 # ffffffffc0208118 <nbase>
ffffffffc0203eae:	000ab703          	ld	a4,0(s5)
ffffffffc0203eb2:	40f506b3          	sub	a3,a0,a5
ffffffffc0203eb6:	f85a                	sd	s6,48(sp)
    return KADDR(page2pa(page));
ffffffffc0203eb8:	000b1b17          	auipc	s6,0xb1
ffffffffc0203ebc:	7d0b0b13          	addi	s6,s6,2000 # ffffffffc02b5688 <npage>
ffffffffc0203ec0:	ec66                	sd	s9,24(sp)
    return page - pages + nbase;
ffffffffc0203ec2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203ec4:	5cfd                	li	s9,-1
ffffffffc0203ec6:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc0203eca:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0203ecc:	00ccdc93          	srli	s9,s9,0xc
ffffffffc0203ed0:	0196f633          	and	a2,a3,s9
ffffffffc0203ed4:	f062                	sd	s8,32(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0203ed6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203ed8:	32f67763          	bgeu	a2,a5,ffffffffc0204206 <do_fork+0x3ba>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203edc:	000bb603          	ld	a2,0(s7)
ffffffffc0203ee0:	000b1b97          	auipc	s7,0xb1
ffffffffc0203ee4:	7a0b8b93          	addi	s7,s7,1952 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0203ee8:	000bb783          	ld	a5,0(s7)
ffffffffc0203eec:	02863c03          	ld	s8,40(a2)
ffffffffc0203ef0:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203ef2:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0203ef4:	020c0863          	beqz	s8,ffffffffc0203f24 <do_fork+0xd8>
    if (clone_flags & CLONE_VM)
ffffffffc0203ef8:	100d7793          	andi	a5,s10,256
ffffffffc0203efc:	18078863          	beqz	a5,ffffffffc020408c <do_fork+0x240>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203f00:	030c2703          	lw	a4,48(s8)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f04:	018c3783          	ld	a5,24(s8)
ffffffffc0203f08:	c02006b7          	lui	a3,0xc0200
ffffffffc0203f0c:	2705                	addiw	a4,a4,1
ffffffffc0203f0e:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc0203f12:	03843423          	sd	s8,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f16:	30d7e463          	bltu	a5,a3,ffffffffc020421e <do_fork+0x3d2>
ffffffffc0203f1a:	000bb703          	ld	a4,0(s7)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f1e:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f20:	8f99                	sub	a5,a5,a4
ffffffffc0203f22:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f24:	6789                	lui	a5,0x2
ffffffffc0203f26:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7048>
ffffffffc0203f2a:	96be                	add	a3,a3,a5
ffffffffc0203f2c:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0203f2e:	87b6                	mv	a5,a3
ffffffffc0203f30:	12048713          	addi	a4,s1,288
ffffffffc0203f34:	6890                	ld	a2,16(s1)
ffffffffc0203f36:	6088                	ld	a0,0(s1)
ffffffffc0203f38:	648c                	ld	a1,8(s1)
ffffffffc0203f3a:	eb90                	sd	a2,16(a5)
ffffffffc0203f3c:	e388                	sd	a0,0(a5)
ffffffffc0203f3e:	e78c                	sd	a1,8(a5)
ffffffffc0203f40:	6c90                	ld	a2,24(s1)
ffffffffc0203f42:	02048493          	addi	s1,s1,32
ffffffffc0203f46:	02078793          	addi	a5,a5,32
ffffffffc0203f4a:	fec7bc23          	sd	a2,-8(a5)
ffffffffc0203f4e:	fee493e3          	bne	s1,a4,ffffffffc0203f34 <do_fork+0xe8>
    proc->tf->gpr.a0 = 0;
ffffffffc0203f52:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203f56:	22090163          	beqz	s2,ffffffffc0204178 <do_fork+0x32c>
ffffffffc0203f5a:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203f5e:	00000797          	auipc	a5,0x0
ffffffffc0203f62:	df878793          	addi	a5,a5,-520 # ffffffffc0203d56 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203f66:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203f68:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f6a:	100027f3          	csrr	a5,sstatus
ffffffffc0203f6e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f70:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f72:	22079263          	bnez	a5,ffffffffc0204196 <do_fork+0x34a>
    if (++last_pid >= MAX_PID)
ffffffffc0203f76:	000ad517          	auipc	a0,0xad
ffffffffc0203f7a:	26e52503          	lw	a0,622(a0) # ffffffffc02b11e4 <last_pid.1>
ffffffffc0203f7e:	6789                	lui	a5,0x2
ffffffffc0203f80:	2505                	addiw	a0,a0,1
ffffffffc0203f82:	000ad717          	auipc	a4,0xad
ffffffffc0203f86:	26a72123          	sw	a0,610(a4) # ffffffffc02b11e4 <last_pid.1>
ffffffffc0203f8a:	22f55563          	bge	a0,a5,ffffffffc02041b4 <do_fork+0x368>
    if (last_pid >= next_safe)
ffffffffc0203f8e:	000ad797          	auipc	a5,0xad
ffffffffc0203f92:	2527a783          	lw	a5,594(a5) # ffffffffc02b11e0 <next_safe.0>
ffffffffc0203f96:	000b1497          	auipc	s1,0xb1
ffffffffc0203f9a:	66a48493          	addi	s1,s1,1642 # ffffffffc02b5600 <proc_list>
ffffffffc0203f9e:	06f54563          	blt	a0,a5,ffffffffc0204008 <do_fork+0x1bc>
    return listelm->next;
ffffffffc0203fa2:	000b1497          	auipc	s1,0xb1
ffffffffc0203fa6:	65e48493          	addi	s1,s1,1630 # ffffffffc02b5600 <proc_list>
ffffffffc0203faa:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc0203fae:	6789                	lui	a5,0x2
ffffffffc0203fb0:	000ad717          	auipc	a4,0xad
ffffffffc0203fb4:	22f72823          	sw	a5,560(a4) # ffffffffc02b11e0 <next_safe.0>
ffffffffc0203fb8:	86aa                	mv	a3,a0
ffffffffc0203fba:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0203fbc:	04988063          	beq	a7,s1,ffffffffc0203ffc <do_fork+0x1b0>
ffffffffc0203fc0:	882e                	mv	a6,a1
ffffffffc0203fc2:	87c6                	mv	a5,a7
ffffffffc0203fc4:	6609                	lui	a2,0x2
ffffffffc0203fc6:	a811                	j	ffffffffc0203fda <do_fork+0x18e>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203fc8:	00e6d663          	bge	a3,a4,ffffffffc0203fd4 <do_fork+0x188>
ffffffffc0203fcc:	00c75463          	bge	a4,a2,ffffffffc0203fd4 <do_fork+0x188>
                next_safe = proc->pid;
ffffffffc0203fd0:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203fd2:	4805                	li	a6,1
ffffffffc0203fd4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203fd6:	00978d63          	beq	a5,s1,ffffffffc0203ff0 <do_fork+0x1a4>
            if (proc->pid == last_pid)
ffffffffc0203fda:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6fec>
ffffffffc0203fde:	fed715e3          	bne	a4,a3,ffffffffc0203fc8 <do_fork+0x17c>
                if (++last_pid >= next_safe)
ffffffffc0203fe2:	2685                	addiw	a3,a3,1
ffffffffc0203fe4:	1ec6d163          	bge	a3,a2,ffffffffc02041c6 <do_fork+0x37a>
ffffffffc0203fe8:	679c                	ld	a5,8(a5)
ffffffffc0203fea:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0203fec:	fe9797e3          	bne	a5,s1,ffffffffc0203fda <do_fork+0x18e>
ffffffffc0203ff0:	00080663          	beqz	a6,ffffffffc0203ffc <do_fork+0x1b0>
ffffffffc0203ff4:	000ad797          	auipc	a5,0xad
ffffffffc0203ff8:	1ec7a623          	sw	a2,492(a5) # ffffffffc02b11e0 <next_safe.0>
ffffffffc0203ffc:	c591                	beqz	a1,ffffffffc0204008 <do_fork+0x1bc>
ffffffffc0203ffe:	000ad797          	auipc	a5,0xad
ffffffffc0204002:	1ed7a323          	sw	a3,486(a5) # ffffffffc02b11e4 <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204006:	8536                	mv	a0,a3
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        //    5. 设置进程状态为可运行
        // 分配唯一的PID
        proc->pid = get_pid();
ffffffffc0204008:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020400a:	45a9                	li	a1,10
ffffffffc020400c:	3dc010ef          	jal	ffffffffc02053e8 <hash32>
ffffffffc0204010:	02051793          	slli	a5,a0,0x20
ffffffffc0204014:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204018:	000ad797          	auipc	a5,0xad
ffffffffc020401c:	5e878793          	addi	a5,a5,1512 # ffffffffc02b1600 <hash_list>
ffffffffc0204020:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204022:	6518                	ld	a4,8(a0)
ffffffffc0204024:	0d840793          	addi	a5,s0,216
ffffffffc0204028:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc020402a:	e31c                	sd	a5,0(a4)
ffffffffc020402c:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc020402e:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204030:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204034:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc0204036:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0204038:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc020403a:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020403e:	7b74                	ld	a3,240(a4)
ffffffffc0204040:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc0204042:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc0204044:	e464                	sd	s1,200(s0)
ffffffffc0204046:	10d43023          	sd	a3,256(s0)
ffffffffc020404a:	c299                	beqz	a3,ffffffffc0204050 <do_fork+0x204>
        proc->optr->yptr = proc;
ffffffffc020404c:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc020404e:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc0204050:	000b1797          	auipc	a5,0xb1
ffffffffc0204054:	6487a783          	lw	a5,1608(a5) # ffffffffc02b5698 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204058:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc020405a:	2785                	addiw	a5,a5,1
ffffffffc020405c:	000b1717          	auipc	a4,0xb1
ffffffffc0204060:	62f72e23          	sw	a5,1596(a4) # ffffffffc02b5698 <nr_process>
    if (flag)
ffffffffc0204064:	14091e63          	bnez	s2,ffffffffc02041c0 <do_fork+0x374>
        set_links(proc); // 加入全局进程链表 //////////////+++
    }
    local_intr_restore(intr_flag);

    //   6. 设置进程状态为可运行
    wakeup_proc(proc);
ffffffffc0204068:	8522                	mv	a0,s0
ffffffffc020406a:	0d4010ef          	jal	ffffffffc020513e <wakeup_proc>

    // 7. 设置返回值为子进程的PID
    ret = proc->pid;
ffffffffc020406e:	4048                	lw	a0,4(s0)
ffffffffc0204070:	64e6                	ld	s1,88(sp)
ffffffffc0204072:	7406                	ld	s0,96(sp)
ffffffffc0204074:	6946                	ld	s2,80(sp)
ffffffffc0204076:	6a06                	ld	s4,64(sp)
ffffffffc0204078:	7ae2                	ld	s5,56(sp)
ffffffffc020407a:	7b42                	ld	s6,48(sp)
ffffffffc020407c:	7ba2                	ld	s7,40(sp)
ffffffffc020407e:	7c02                	ld	s8,32(sp)
ffffffffc0204080:	6ce2                	ld	s9,24(sp)
ffffffffc0204082:	6d42                	ld	s10,16(sp)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc0204084:	70a6                	ld	ra,104(sp)
ffffffffc0204086:	69a6                	ld	s3,72(sp)
ffffffffc0204088:	6165                	addi	sp,sp,112
ffffffffc020408a:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc020408c:	e43a                	sd	a4,8(sp)
ffffffffc020408e:	cf6ff0ef          	jal	ffffffffc0203584 <mm_create>
ffffffffc0204092:	8d2a                	mv	s10,a0
ffffffffc0204094:	c959                	beqz	a0,ffffffffc020412a <do_fork+0x2de>
    if ((page = alloc_page()) == NULL)
ffffffffc0204096:	4505                	li	a0,1
ffffffffc0204098:	d27fd0ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc020409c:	c541                	beqz	a0,ffffffffc0204124 <do_fork+0x2d8>
    return page - pages + nbase;
ffffffffc020409e:	000a3683          	ld	a3,0(s4)
ffffffffc02040a2:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc02040a4:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc02040a8:	40d506b3          	sub	a3,a0,a3
ffffffffc02040ac:	8699                	srai	a3,a3,0x6
ffffffffc02040ae:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02040b0:	0196fcb3          	and	s9,a3,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc02040b4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040b6:	14fcf863          	bgeu	s9,a5,ffffffffc0204206 <do_fork+0x3ba>
ffffffffc02040ba:	000bb783          	ld	a5,0(s7)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02040be:	000b1597          	auipc	a1,0xb1
ffffffffc02040c2:	5ba5b583          	ld	a1,1466(a1) # ffffffffc02b5678 <boot_pgdir_va>
ffffffffc02040c6:	864e                	mv	a2,s3
ffffffffc02040c8:	00f689b3          	add	s3,a3,a5
ffffffffc02040cc:	854e                	mv	a0,s3
ffffffffc02040ce:	7c2010ef          	jal	ffffffffc0205890 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02040d2:	038c0c93          	addi	s9,s8,56
    mm->pgdir = pgdir;
ffffffffc02040d6:	013d3c23          	sd	s3,24(s10)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02040da:	4785                	li	a5,1
ffffffffc02040dc:	40fcb7af          	amoor.d	a5,a5,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02040e0:	03f79713          	slli	a4,a5,0x3f
ffffffffc02040e4:	03f75793          	srli	a5,a4,0x3f
ffffffffc02040e8:	4985                	li	s3,1
ffffffffc02040ea:	cb91                	beqz	a5,ffffffffc02040fe <do_fork+0x2b2>
    {
        schedule();
ffffffffc02040ec:	14a010ef          	jal	ffffffffc0205236 <schedule>
ffffffffc02040f0:	413cb7af          	amoor.d	a5,s3,(s9)
    while (!try_lock(lock))
ffffffffc02040f4:	03f79713          	slli	a4,a5,0x3f
ffffffffc02040f8:	03f75793          	srli	a5,a4,0x3f
ffffffffc02040fc:	fbe5                	bnez	a5,ffffffffc02040ec <do_fork+0x2a0>
        ret = dup_mmap(mm, oldmm);
ffffffffc02040fe:	85e2                	mv	a1,s8
ffffffffc0204100:	856a                	mv	a0,s10
ffffffffc0204102:	edeff0ef          	jal	ffffffffc02037e0 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204106:	57f9                	li	a5,-2
ffffffffc0204108:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc020410c:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020410e:	12078563          	beqz	a5,ffffffffc0204238 <do_fork+0x3ec>
    if ((mm = mm_create()) == NULL)
ffffffffc0204112:	8c6a                	mv	s8,s10
    if (ret != 0)
ffffffffc0204114:	de0506e3          	beqz	a0,ffffffffc0203f00 <do_fork+0xb4>
    exit_mmap(mm);
ffffffffc0204118:	856a                	mv	a0,s10
ffffffffc020411a:	f5eff0ef          	jal	ffffffffc0203878 <exit_mmap>
    put_pgdir(mm);
ffffffffc020411e:	856a                	mv	a0,s10
ffffffffc0204120:	c45ff0ef          	jal	ffffffffc0203d64 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204124:	856a                	mv	a0,s10
ffffffffc0204126:	d9cff0ef          	jal	ffffffffc02036c2 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020412a:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020412c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204130:	0af6ef63          	bltu	a3,a5,ffffffffc02041ee <do_fork+0x3a2>
ffffffffc0204134:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage)
ffffffffc0204138:	000b3703          	ld	a4,0(s6)
    return pa2page(PADDR(kva));
ffffffffc020413c:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204140:	83b1                	srli	a5,a5,0xc
ffffffffc0204142:	08e7fa63          	bgeu	a5,a4,ffffffffc02041d6 <do_fork+0x38a>
    return &pages[PPN(pa) - nbase];
ffffffffc0204146:	000ab703          	ld	a4,0(s5)
ffffffffc020414a:	000a3503          	ld	a0,0(s4)
ffffffffc020414e:	4589                	li	a1,2
ffffffffc0204150:	8f99                	sub	a5,a5,a4
ffffffffc0204152:	079a                	slli	a5,a5,0x6
ffffffffc0204154:	953e                	add	a0,a0,a5
ffffffffc0204156:	ca3fd0ef          	jal	ffffffffc0201df8 <free_pages>
}
ffffffffc020415a:	6a06                	ld	s4,64(sp)
ffffffffc020415c:	7ae2                	ld	s5,56(sp)
ffffffffc020415e:	7b42                	ld	s6,48(sp)
ffffffffc0204160:	7c02                	ld	s8,32(sp)
ffffffffc0204162:	6ce2                	ld	s9,24(sp)
    kfree(proc);
ffffffffc0204164:	8522                	mv	a0,s0
ffffffffc0204166:	b3dfd0ef          	jal	ffffffffc0201ca2 <kfree>
ffffffffc020416a:	7ba2                	ld	s7,40(sp)
ffffffffc020416c:	7406                	ld	s0,96(sp)
ffffffffc020416e:	64e6                	ld	s1,88(sp)
ffffffffc0204170:	6946                	ld	s2,80(sp)
ffffffffc0204172:	6d42                	ld	s10,16(sp)
    ret = -E_NO_MEM;
ffffffffc0204174:	5571                	li	a0,-4
    return ret;
ffffffffc0204176:	b739                	j	ffffffffc0204084 <do_fork+0x238>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204178:	8936                	mv	s2,a3
ffffffffc020417a:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020417e:	00000797          	auipc	a5,0x0
ffffffffc0204182:	bd878793          	addi	a5,a5,-1064 # ffffffffc0203d56 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204186:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204188:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020418a:	100027f3          	csrr	a5,sstatus
ffffffffc020418e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204190:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204192:	de0782e3          	beqz	a5,ffffffffc0203f76 <do_fork+0x12a>
        intr_disable();
ffffffffc0204196:	f68fc0ef          	jal	ffffffffc02008fe <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc020419a:	000ad517          	auipc	a0,0xad
ffffffffc020419e:	04a52503          	lw	a0,74(a0) # ffffffffc02b11e4 <last_pid.1>
ffffffffc02041a2:	6789                	lui	a5,0x2
        return 1;
ffffffffc02041a4:	4905                	li	s2,1
ffffffffc02041a6:	2505                	addiw	a0,a0,1
ffffffffc02041a8:	000ad717          	auipc	a4,0xad
ffffffffc02041ac:	02a72e23          	sw	a0,60(a4) # ffffffffc02b11e4 <last_pid.1>
ffffffffc02041b0:	dcf54fe3          	blt	a0,a5,ffffffffc0203f8e <do_fork+0x142>
        last_pid = 1;
ffffffffc02041b4:	4505                	li	a0,1
ffffffffc02041b6:	000ad797          	auipc	a5,0xad
ffffffffc02041ba:	02a7a723          	sw	a0,46(a5) # ffffffffc02b11e4 <last_pid.1>
        goto inside;
ffffffffc02041be:	b3d5                	j	ffffffffc0203fa2 <do_fork+0x156>
        intr_enable();
ffffffffc02041c0:	f38fc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02041c4:	b555                	j	ffffffffc0204068 <do_fork+0x21c>
                    if (last_pid >= MAX_PID)
ffffffffc02041c6:	6789                	lui	a5,0x2
ffffffffc02041c8:	00f6c363          	blt	a3,a5,ffffffffc02041ce <do_fork+0x382>
                        last_pid = 1;
ffffffffc02041cc:	4685                	li	a3,1
                    goto repeat;
ffffffffc02041ce:	4585                	li	a1,1
ffffffffc02041d0:	b3f5                	j	ffffffffc0203fbc <do_fork+0x170>
    int ret = -E_NO_FREE_PROC;
ffffffffc02041d2:	556d                	li	a0,-5
ffffffffc02041d4:	bd45                	j	ffffffffc0204084 <do_fork+0x238>
        panic("pa2page called with invalid pa");
ffffffffc02041d6:	00002617          	auipc	a2,0x2
ffffffffc02041da:	53260613          	addi	a2,a2,1330 # ffffffffc0206708 <etext+0xe60>
ffffffffc02041de:	06900593          	li	a1,105
ffffffffc02041e2:	00002517          	auipc	a0,0x2
ffffffffc02041e6:	47e50513          	addi	a0,a0,1150 # ffffffffc0206660 <etext+0xdb8>
ffffffffc02041ea:	a60fc0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc02041ee:	00002617          	auipc	a2,0x2
ffffffffc02041f2:	4f260613          	addi	a2,a2,1266 # ffffffffc02066e0 <etext+0xe38>
ffffffffc02041f6:	07700593          	li	a1,119
ffffffffc02041fa:	00002517          	auipc	a0,0x2
ffffffffc02041fe:	46650513          	addi	a0,a0,1126 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0204202:	a48fc0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc0204206:	00002617          	auipc	a2,0x2
ffffffffc020420a:	43260613          	addi	a2,a2,1074 # ffffffffc0206638 <etext+0xd90>
ffffffffc020420e:	07100593          	li	a1,113
ffffffffc0204212:	00002517          	auipc	a0,0x2
ffffffffc0204216:	44e50513          	addi	a0,a0,1102 # ffffffffc0206660 <etext+0xdb8>
ffffffffc020421a:	a30fc0ef          	jal	ffffffffc020044a <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020421e:	86be                	mv	a3,a5
ffffffffc0204220:	00002617          	auipc	a2,0x2
ffffffffc0204224:	4c060613          	addi	a2,a2,1216 # ffffffffc02066e0 <etext+0xe38>
ffffffffc0204228:	19f00593          	li	a1,415
ffffffffc020422c:	00003517          	auipc	a0,0x3
ffffffffc0204230:	df450513          	addi	a0,a0,-524 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204234:	a16fc0ef          	jal	ffffffffc020044a <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204238:	00003617          	auipc	a2,0x3
ffffffffc020423c:	dc060613          	addi	a2,a2,-576 # ffffffffc0206ff8 <etext+0x1750>
ffffffffc0204240:	04000593          	li	a1,64
ffffffffc0204244:	00003517          	auipc	a0,0x3
ffffffffc0204248:	dc450513          	addi	a0,a0,-572 # ffffffffc0207008 <etext+0x1760>
ffffffffc020424c:	9fefc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204250 <kernel_thread>:
{
ffffffffc0204250:	7129                	addi	sp,sp,-320
ffffffffc0204252:	fa22                	sd	s0,304(sp)
ffffffffc0204254:	f626                	sd	s1,296(sp)
ffffffffc0204256:	f24a                	sd	s2,288(sp)
ffffffffc0204258:	842a                	mv	s0,a0
ffffffffc020425a:	84ae                	mv	s1,a1
ffffffffc020425c:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020425e:	850a                	mv	a0,sp
ffffffffc0204260:	12000613          	li	a2,288
ffffffffc0204264:	4581                	li	a1,0
{
ffffffffc0204266:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204268:	616010ef          	jal	ffffffffc020587e <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020426c:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020426e:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204270:	100027f3          	csrr	a5,sstatus
ffffffffc0204274:	edd7f793          	andi	a5,a5,-291
ffffffffc0204278:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020427c:	860a                	mv	a2,sp
ffffffffc020427e:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204282:	00000717          	auipc	a4,0x0
ffffffffc0204286:	a3270713          	addi	a4,a4,-1486 # ffffffffc0203cb4 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020428a:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020428c:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020428e:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204290:	bbdff0ef          	jal	ffffffffc0203e4c <do_fork>
}
ffffffffc0204294:	70f2                	ld	ra,312(sp)
ffffffffc0204296:	7452                	ld	s0,304(sp)
ffffffffc0204298:	74b2                	ld	s1,296(sp)
ffffffffc020429a:	7912                	ld	s2,288(sp)
ffffffffc020429c:	6131                	addi	sp,sp,320
ffffffffc020429e:	8082                	ret

ffffffffc02042a0 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc02042a0:	7179                	addi	sp,sp,-48
ffffffffc02042a2:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02042a4:	000b1417          	auipc	s0,0xb1
ffffffffc02042a8:	3fc40413          	addi	s0,s0,1020 # ffffffffc02b56a0 <current>
ffffffffc02042ac:	601c                	ld	a5,0(s0)
ffffffffc02042ae:	000b1717          	auipc	a4,0xb1
ffffffffc02042b2:	40273703          	ld	a4,1026(a4) # ffffffffc02b56b0 <idleproc>
{
ffffffffc02042b6:	f406                	sd	ra,40(sp)
ffffffffc02042b8:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc02042ba:	0ce78b63          	beq	a5,a4,ffffffffc0204390 <do_exit+0xf0>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc02042be:	000b1497          	auipc	s1,0xb1
ffffffffc02042c2:	3ea48493          	addi	s1,s1,1002 # ffffffffc02b56a8 <initproc>
ffffffffc02042c6:	6098                	ld	a4,0(s1)
ffffffffc02042c8:	e84a                	sd	s2,16(sp)
ffffffffc02042ca:	0ee78a63          	beq	a5,a4,ffffffffc02043be <do_exit+0x11e>
ffffffffc02042ce:	892a                	mv	s2,a0
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc02042d0:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc02042d2:	c115                	beqz	a0,ffffffffc02042f6 <do_exit+0x56>
ffffffffc02042d4:	000b1797          	auipc	a5,0xb1
ffffffffc02042d8:	39c7b783          	ld	a5,924(a5) # ffffffffc02b5670 <boot_pgdir_pa>
ffffffffc02042dc:	577d                	li	a4,-1
ffffffffc02042de:	177e                	slli	a4,a4,0x3f
ffffffffc02042e0:	83b1                	srli	a5,a5,0xc
ffffffffc02042e2:	8fd9                	or	a5,a5,a4
ffffffffc02042e4:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02042e8:	591c                	lw	a5,48(a0)
ffffffffc02042ea:	37fd                	addiw	a5,a5,-1
ffffffffc02042ec:	d91c                	sw	a5,48(a0)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc02042ee:	cfd5                	beqz	a5,ffffffffc02043aa <do_exit+0x10a>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc02042f0:	601c                	ld	a5,0(s0)
ffffffffc02042f2:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc02042f6:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc02042f8:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02042fc:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02042fe:	100027f3          	csrr	a5,sstatus
ffffffffc0204302:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204304:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204306:	ebe1                	bnez	a5,ffffffffc02043d6 <do_exit+0x136>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc0204308:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020430a:	800007b7          	lui	a5,0x80000
ffffffffc020430e:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
        proc = current->parent;
ffffffffc0204310:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204312:	0ec52703          	lw	a4,236(a0)
ffffffffc0204316:	0cf70463          	beq	a4,a5,ffffffffc02043de <do_exit+0x13e>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc020431a:	6018                	ld	a4,0(s0)
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc020431c:	800005b7          	lui	a1,0x80000
ffffffffc0204320:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
        while (current->cptr != NULL)
ffffffffc0204322:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204324:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc0204326:	e789                	bnez	a5,ffffffffc0204330 <do_exit+0x90>
ffffffffc0204328:	a83d                	j	ffffffffc0204366 <do_exit+0xc6>
ffffffffc020432a:	6018                	ld	a4,0(s0)
ffffffffc020432c:	7b7c                	ld	a5,240(a4)
ffffffffc020432e:	cf85                	beqz	a5,ffffffffc0204366 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc0204330:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204334:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204336:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc0204338:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020433c:	7978                	ld	a4,240(a0)
ffffffffc020433e:	10e7b023          	sd	a4,256(a5)
ffffffffc0204342:	c311                	beqz	a4,ffffffffc0204346 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc0204344:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204346:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204348:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020434a:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020434c:	fcc71fe3          	bne	a4,a2,ffffffffc020432a <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204350:	0ec52783          	lw	a5,236(a0)
ffffffffc0204354:	fcb79be3          	bne	a5,a1,ffffffffc020432a <do_exit+0x8a>
                {
                    wakeup_proc(initproc);
ffffffffc0204358:	5e7000ef          	jal	ffffffffc020513e <wakeup_proc>
ffffffffc020435c:	800005b7          	lui	a1,0x80000
ffffffffc0204360:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
ffffffffc0204362:	460d                	li	a2,3
ffffffffc0204364:	b7d9                	j	ffffffffc020432a <do_exit+0x8a>
    if (flag)
ffffffffc0204366:	02091263          	bnez	s2,ffffffffc020438a <do_exit+0xea>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc020436a:	6cd000ef          	jal	ffffffffc0205236 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020436e:	601c                	ld	a5,0(s0)
ffffffffc0204370:	00003617          	auipc	a2,0x3
ffffffffc0204374:	ce860613          	addi	a2,a2,-792 # ffffffffc0207058 <etext+0x17b0>
ffffffffc0204378:	25b00593          	li	a1,603
ffffffffc020437c:	43d4                	lw	a3,4(a5)
ffffffffc020437e:	00003517          	auipc	a0,0x3
ffffffffc0204382:	ca250513          	addi	a0,a0,-862 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204386:	8c4fc0ef          	jal	ffffffffc020044a <__panic>
        intr_enable();
ffffffffc020438a:	d6efc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020438e:	bff1                	j	ffffffffc020436a <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc0204390:	00003617          	auipc	a2,0x3
ffffffffc0204394:	ca860613          	addi	a2,a2,-856 # ffffffffc0207038 <etext+0x1790>
ffffffffc0204398:	22700593          	li	a1,551
ffffffffc020439c:	00003517          	auipc	a0,0x3
ffffffffc02043a0:	c8450513          	addi	a0,a0,-892 # ffffffffc0207020 <etext+0x1778>
ffffffffc02043a4:	e84a                	sd	s2,16(sp)
ffffffffc02043a6:	8a4fc0ef          	jal	ffffffffc020044a <__panic>
            exit_mmap(mm);
ffffffffc02043aa:	e42a                	sd	a0,8(sp)
ffffffffc02043ac:	cccff0ef          	jal	ffffffffc0203878 <exit_mmap>
            put_pgdir(mm);
ffffffffc02043b0:	6522                	ld	a0,8(sp)
ffffffffc02043b2:	9b3ff0ef          	jal	ffffffffc0203d64 <put_pgdir>
            mm_destroy(mm);
ffffffffc02043b6:	6522                	ld	a0,8(sp)
ffffffffc02043b8:	b0aff0ef          	jal	ffffffffc02036c2 <mm_destroy>
ffffffffc02043bc:	bf15                	j	ffffffffc02042f0 <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc02043be:	00003617          	auipc	a2,0x3
ffffffffc02043c2:	c8a60613          	addi	a2,a2,-886 # ffffffffc0207048 <etext+0x17a0>
ffffffffc02043c6:	22b00593          	li	a1,555
ffffffffc02043ca:	00003517          	auipc	a0,0x3
ffffffffc02043ce:	c5650513          	addi	a0,a0,-938 # ffffffffc0207020 <etext+0x1778>
ffffffffc02043d2:	878fc0ef          	jal	ffffffffc020044a <__panic>
        intr_disable();
ffffffffc02043d6:	d28fc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc02043da:	4905                	li	s2,1
ffffffffc02043dc:	b735                	j	ffffffffc0204308 <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc02043de:	561000ef          	jal	ffffffffc020513e <wakeup_proc>
ffffffffc02043e2:	bf25                	j	ffffffffc020431a <do_exit+0x7a>

ffffffffc02043e4 <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc02043e4:	7179                	addi	sp,sp,-48
ffffffffc02043e6:	ec26                	sd	s1,24(sp)
ffffffffc02043e8:	e84a                	sd	s2,16(sp)
ffffffffc02043ea:	e44e                	sd	s3,8(sp)
ffffffffc02043ec:	f406                	sd	ra,40(sp)
ffffffffc02043ee:	f022                	sd	s0,32(sp)
ffffffffc02043f0:	84aa                	mv	s1,a0
ffffffffc02043f2:	892e                	mv	s2,a1
ffffffffc02043f4:	000b1997          	auipc	s3,0xb1
ffffffffc02043f8:	2ac98993          	addi	s3,s3,684 # ffffffffc02b56a0 <current>

    struct proc_struct *proc;
    bool intr_flag, haskid;
repeat:
    haskid = 0;
    if (pid != 0)
ffffffffc02043fc:	cd19                	beqz	a0,ffffffffc020441a <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc02043fe:	6789                	lui	a5,0x2
ffffffffc0204400:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f2a>
ffffffffc0204402:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204406:	12e7f563          	bgeu	a5,a4,ffffffffc0204530 <do_wait.part.0+0x14c>
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc020440a:	70a2                	ld	ra,40(sp)
ffffffffc020440c:	7402                	ld	s0,32(sp)
ffffffffc020440e:	64e2                	ld	s1,24(sp)
ffffffffc0204410:	6942                	ld	s2,16(sp)
ffffffffc0204412:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204414:	5579                	li	a0,-2
}
ffffffffc0204416:	6145                	addi	sp,sp,48
ffffffffc0204418:	8082                	ret
        proc = current->cptr;
ffffffffc020441a:	0009b703          	ld	a4,0(s3)
ffffffffc020441e:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204420:	d46d                	beqz	s0,ffffffffc020440a <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204422:	468d                	li	a3,3
ffffffffc0204424:	a021                	j	ffffffffc020442c <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204426:	10043403          	ld	s0,256(s0)
ffffffffc020442a:	c075                	beqz	s0,ffffffffc020450e <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020442c:	401c                	lw	a5,0(s0)
ffffffffc020442e:	fed79ce3          	bne	a5,a3,ffffffffc0204426 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc0204432:	000b1797          	auipc	a5,0xb1
ffffffffc0204436:	27e7b783          	ld	a5,638(a5) # ffffffffc02b56b0 <idleproc>
ffffffffc020443a:	14878263          	beq	a5,s0,ffffffffc020457e <do_wait.part.0+0x19a>
ffffffffc020443e:	000b1797          	auipc	a5,0xb1
ffffffffc0204442:	26a7b783          	ld	a5,618(a5) # ffffffffc02b56a8 <initproc>
ffffffffc0204446:	12f40c63          	beq	s0,a5,ffffffffc020457e <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc020444a:	00090663          	beqz	s2,ffffffffc0204456 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc020444e:	0e842783          	lw	a5,232(s0)
ffffffffc0204452:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204456:	100027f3          	csrr	a5,sstatus
ffffffffc020445a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020445c:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020445e:	10079963          	bnez	a5,ffffffffc0204570 <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204462:	6c74                	ld	a3,216(s0)
ffffffffc0204464:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc0204466:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc020446a:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020446c:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020446e:	6474                	ld	a3,200(s0)
ffffffffc0204470:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc0204472:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204474:	e314                	sd	a3,0(a4)
ffffffffc0204476:	c789                	beqz	a5,ffffffffc0204480 <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc0204478:	7c78                	ld	a4,248(s0)
ffffffffc020447a:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc020447c:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc0204480:	7c78                	ld	a4,248(s0)
ffffffffc0204482:	c36d                	beqz	a4,ffffffffc0204564 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc0204484:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc0204488:	000b1797          	auipc	a5,0xb1
ffffffffc020448c:	2107a783          	lw	a5,528(a5) # ffffffffc02b5698 <nr_process>
ffffffffc0204490:	37fd                	addiw	a5,a5,-1
ffffffffc0204492:	000b1717          	auipc	a4,0xb1
ffffffffc0204496:	20f72323          	sw	a5,518(a4) # ffffffffc02b5698 <nr_process>
    if (flag)
ffffffffc020449a:	e271                	bnez	a2,ffffffffc020455e <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020449c:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020449e:	c02007b7          	lui	a5,0xc0200
ffffffffc02044a2:	10f6e663          	bltu	a3,a5,ffffffffc02045ae <do_wait.part.0+0x1ca>
ffffffffc02044a6:	000b1717          	auipc	a4,0xb1
ffffffffc02044aa:	1da73703          	ld	a4,474(a4) # ffffffffc02b5680 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc02044ae:	000b1797          	auipc	a5,0xb1
ffffffffc02044b2:	1da7b783          	ld	a5,474(a5) # ffffffffc02b5688 <npage>
    return pa2page(PADDR(kva));
ffffffffc02044b6:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc02044b8:	82b1                	srli	a3,a3,0xc
ffffffffc02044ba:	0cf6fe63          	bgeu	a3,a5,ffffffffc0204596 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc02044be:	00004797          	auipc	a5,0x4
ffffffffc02044c2:	c5a7b783          	ld	a5,-934(a5) # ffffffffc0208118 <nbase>
ffffffffc02044c6:	000b1517          	auipc	a0,0xb1
ffffffffc02044ca:	1ca53503          	ld	a0,458(a0) # ffffffffc02b5690 <pages>
ffffffffc02044ce:	4589                	li	a1,2
ffffffffc02044d0:	8e9d                	sub	a3,a3,a5
ffffffffc02044d2:	069a                	slli	a3,a3,0x6
ffffffffc02044d4:	9536                	add	a0,a0,a3
ffffffffc02044d6:	923fd0ef          	jal	ffffffffc0201df8 <free_pages>
    kfree(proc);
ffffffffc02044da:	8522                	mv	a0,s0
ffffffffc02044dc:	fc6fd0ef          	jal	ffffffffc0201ca2 <kfree>
}
ffffffffc02044e0:	70a2                	ld	ra,40(sp)
ffffffffc02044e2:	7402                	ld	s0,32(sp)
ffffffffc02044e4:	64e2                	ld	s1,24(sp)
ffffffffc02044e6:	6942                	ld	s2,16(sp)
ffffffffc02044e8:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc02044ea:	4501                	li	a0,0
}
ffffffffc02044ec:	6145                	addi	sp,sp,48
ffffffffc02044ee:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02044f0:	000b1997          	auipc	s3,0xb1
ffffffffc02044f4:	1b098993          	addi	s3,s3,432 # ffffffffc02b56a0 <current>
ffffffffc02044f8:	0009b703          	ld	a4,0(s3)
ffffffffc02044fc:	f487b683          	ld	a3,-184(a5)
ffffffffc0204500:	f0e695e3          	bne	a3,a4,ffffffffc020440a <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204504:	f287a603          	lw	a2,-216(a5)
ffffffffc0204508:	468d                	li	a3,3
ffffffffc020450a:	06d60063          	beq	a2,a3,ffffffffc020456a <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc020450e:	800007b7          	lui	a5,0x80000
ffffffffc0204512:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
        current->state = PROC_SLEEPING;
ffffffffc0204514:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc0204516:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc020451a:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc020451c:	51b000ef          	jal	ffffffffc0205236 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204520:	0009b783          	ld	a5,0(s3)
ffffffffc0204524:	0b07a783          	lw	a5,176(a5)
ffffffffc0204528:	8b85                	andi	a5,a5,1
ffffffffc020452a:	e7b9                	bnez	a5,ffffffffc0204578 <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc020452c:	ee0487e3          	beqz	s1,ffffffffc020441a <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204530:	45a9                	li	a1,10
ffffffffc0204532:	8526                	mv	a0,s1
ffffffffc0204534:	6b5000ef          	jal	ffffffffc02053e8 <hash32>
ffffffffc0204538:	02051793          	slli	a5,a0,0x20
ffffffffc020453c:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204540:	000ad797          	auipc	a5,0xad
ffffffffc0204544:	0c078793          	addi	a5,a5,192 # ffffffffc02b1600 <hash_list>
ffffffffc0204548:	953e                	add	a0,a0,a5
ffffffffc020454a:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc020454c:	a029                	j	ffffffffc0204556 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc020454e:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204552:	f8970fe3          	beq	a4,s1,ffffffffc02044f0 <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc0204556:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204558:	fef51be3          	bne	a0,a5,ffffffffc020454e <do_wait.part.0+0x16a>
ffffffffc020455c:	b57d                	j	ffffffffc020440a <do_wait.part.0+0x26>
        intr_enable();
ffffffffc020455e:	b9afc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0204562:	bf2d                	j	ffffffffc020449c <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc0204564:	7018                	ld	a4,32(s0)
ffffffffc0204566:	fb7c                	sd	a5,240(a4)
ffffffffc0204568:	b705                	j	ffffffffc0204488 <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020456a:	f2878413          	addi	s0,a5,-216
ffffffffc020456e:	b5d1                	j	ffffffffc0204432 <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc0204570:	b8efc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0204574:	4605                	li	a2,1
ffffffffc0204576:	b5f5                	j	ffffffffc0204462 <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc0204578:	555d                	li	a0,-9
ffffffffc020457a:	d27ff0ef          	jal	ffffffffc02042a0 <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc020457e:	00003617          	auipc	a2,0x3
ffffffffc0204582:	afa60613          	addi	a2,a2,-1286 # ffffffffc0207078 <etext+0x17d0>
ffffffffc0204586:	37c00593          	li	a1,892
ffffffffc020458a:	00003517          	auipc	a0,0x3
ffffffffc020458e:	a9650513          	addi	a0,a0,-1386 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204592:	eb9fb0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204596:	00002617          	auipc	a2,0x2
ffffffffc020459a:	17260613          	addi	a2,a2,370 # ffffffffc0206708 <etext+0xe60>
ffffffffc020459e:	06900593          	li	a1,105
ffffffffc02045a2:	00002517          	auipc	a0,0x2
ffffffffc02045a6:	0be50513          	addi	a0,a0,190 # ffffffffc0206660 <etext+0xdb8>
ffffffffc02045aa:	ea1fb0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc02045ae:	00002617          	auipc	a2,0x2
ffffffffc02045b2:	13260613          	addi	a2,a2,306 # ffffffffc02066e0 <etext+0xe38>
ffffffffc02045b6:	07700593          	li	a1,119
ffffffffc02045ba:	00002517          	auipc	a0,0x2
ffffffffc02045be:	0a650513          	addi	a0,a0,166 # ffffffffc0206660 <etext+0xdb8>
ffffffffc02045c2:	e89fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02045c6 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02045c6:	1141                	addi	sp,sp,-16
ffffffffc02045c8:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02045ca:	867fd0ef          	jal	ffffffffc0201e30 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02045ce:	e2afd0ef          	jal	ffffffffc0201bf8 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02045d2:	4601                	li	a2,0
ffffffffc02045d4:	4581                	li	a1,0
ffffffffc02045d6:	00000517          	auipc	a0,0x0
ffffffffc02045da:	6b050513          	addi	a0,a0,1712 # ffffffffc0204c86 <user_main>
ffffffffc02045de:	c73ff0ef          	jal	ffffffffc0204250 <kernel_thread>
    if (pid <= 0)
ffffffffc02045e2:	00a04563          	bgtz	a0,ffffffffc02045ec <init_main+0x26>
ffffffffc02045e6:	a071                	j	ffffffffc0204672 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02045e8:	44f000ef          	jal	ffffffffc0205236 <schedule>
    if (code_store != NULL)
ffffffffc02045ec:	4581                	li	a1,0
ffffffffc02045ee:	4501                	li	a0,0
ffffffffc02045f0:	df5ff0ef          	jal	ffffffffc02043e4 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02045f4:	d975                	beqz	a0,ffffffffc02045e8 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02045f6:	00003517          	auipc	a0,0x3
ffffffffc02045fa:	ac250513          	addi	a0,a0,-1342 # ffffffffc02070b8 <etext+0x1810>
ffffffffc02045fe:	b9bfb0ef          	jal	ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204602:	000b1797          	auipc	a5,0xb1
ffffffffc0204606:	0a67b783          	ld	a5,166(a5) # ffffffffc02b56a8 <initproc>
ffffffffc020460a:	7bf8                	ld	a4,240(a5)
ffffffffc020460c:	e339                	bnez	a4,ffffffffc0204652 <init_main+0x8c>
ffffffffc020460e:	7ff8                	ld	a4,248(a5)
ffffffffc0204610:	e329                	bnez	a4,ffffffffc0204652 <init_main+0x8c>
ffffffffc0204612:	1007b703          	ld	a4,256(a5)
ffffffffc0204616:	ef15                	bnez	a4,ffffffffc0204652 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204618:	000b1697          	auipc	a3,0xb1
ffffffffc020461c:	0806a683          	lw	a3,128(a3) # ffffffffc02b5698 <nr_process>
ffffffffc0204620:	4709                	li	a4,2
ffffffffc0204622:	0ae69463          	bne	a3,a4,ffffffffc02046ca <init_main+0x104>
ffffffffc0204626:	000b1697          	auipc	a3,0xb1
ffffffffc020462a:	fda68693          	addi	a3,a3,-38 # ffffffffc02b5600 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020462e:	6698                	ld	a4,8(a3)
ffffffffc0204630:	0c878793          	addi	a5,a5,200
ffffffffc0204634:	06f71b63          	bne	a4,a5,ffffffffc02046aa <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204638:	629c                	ld	a5,0(a3)
ffffffffc020463a:	04f71863          	bne	a4,a5,ffffffffc020468a <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc020463e:	00003517          	auipc	a0,0x3
ffffffffc0204642:	b6250513          	addi	a0,a0,-1182 # ffffffffc02071a0 <etext+0x18f8>
ffffffffc0204646:	b53fb0ef          	jal	ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc020464a:	60a2                	ld	ra,8(sp)
ffffffffc020464c:	4501                	li	a0,0
ffffffffc020464e:	0141                	addi	sp,sp,16
ffffffffc0204650:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204652:	00003697          	auipc	a3,0x3
ffffffffc0204656:	a8e68693          	addi	a3,a3,-1394 # ffffffffc02070e0 <etext+0x1838>
ffffffffc020465a:	00002617          	auipc	a2,0x2
ffffffffc020465e:	c2e60613          	addi	a2,a2,-978 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0204662:	3e800593          	li	a1,1000
ffffffffc0204666:	00003517          	auipc	a0,0x3
ffffffffc020466a:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0207020 <etext+0x1778>
ffffffffc020466e:	dddfb0ef          	jal	ffffffffc020044a <__panic>
        panic("create user_main failed.\n");
ffffffffc0204672:	00003617          	auipc	a2,0x3
ffffffffc0204676:	a2660613          	addi	a2,a2,-1498 # ffffffffc0207098 <etext+0x17f0>
ffffffffc020467a:	3df00593          	li	a1,991
ffffffffc020467e:	00003517          	auipc	a0,0x3
ffffffffc0204682:	9a250513          	addi	a0,a0,-1630 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204686:	dc5fb0ef          	jal	ffffffffc020044a <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020468a:	00003697          	auipc	a3,0x3
ffffffffc020468e:	ae668693          	addi	a3,a3,-1306 # ffffffffc0207170 <etext+0x18c8>
ffffffffc0204692:	00002617          	auipc	a2,0x2
ffffffffc0204696:	bf660613          	addi	a2,a2,-1034 # ffffffffc0206288 <etext+0x9e0>
ffffffffc020469a:	3eb00593          	li	a1,1003
ffffffffc020469e:	00003517          	auipc	a0,0x3
ffffffffc02046a2:	98250513          	addi	a0,a0,-1662 # ffffffffc0207020 <etext+0x1778>
ffffffffc02046a6:	da5fb0ef          	jal	ffffffffc020044a <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02046aa:	00003697          	auipc	a3,0x3
ffffffffc02046ae:	a9668693          	addi	a3,a3,-1386 # ffffffffc0207140 <etext+0x1898>
ffffffffc02046b2:	00002617          	auipc	a2,0x2
ffffffffc02046b6:	bd660613          	addi	a2,a2,-1066 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02046ba:	3ea00593          	li	a1,1002
ffffffffc02046be:	00003517          	auipc	a0,0x3
ffffffffc02046c2:	96250513          	addi	a0,a0,-1694 # ffffffffc0207020 <etext+0x1778>
ffffffffc02046c6:	d85fb0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_process == 2);
ffffffffc02046ca:	00003697          	auipc	a3,0x3
ffffffffc02046ce:	a6668693          	addi	a3,a3,-1434 # ffffffffc0207130 <etext+0x1888>
ffffffffc02046d2:	00002617          	auipc	a2,0x2
ffffffffc02046d6:	bb660613          	addi	a2,a2,-1098 # ffffffffc0206288 <etext+0x9e0>
ffffffffc02046da:	3e900593          	li	a1,1001
ffffffffc02046de:	00003517          	auipc	a0,0x3
ffffffffc02046e2:	94250513          	addi	a0,a0,-1726 # ffffffffc0207020 <etext+0x1778>
ffffffffc02046e6:	d65fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02046ea <do_execve>:
{
ffffffffc02046ea:	7171                	addi	sp,sp,-176
ffffffffc02046ec:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02046ee:	000b1d17          	auipc	s10,0xb1
ffffffffc02046f2:	fb2d0d13          	addi	s10,s10,-78 # ffffffffc02b56a0 <current>
ffffffffc02046f6:	000d3783          	ld	a5,0(s10)
{
ffffffffc02046fa:	e94a                	sd	s2,144(sp)
ffffffffc02046fc:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02046fe:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204702:	84ae                	mv	s1,a1
ffffffffc0204704:	e54e                	sd	s3,136(sp)
ffffffffc0204706:	ec32                	sd	a2,24(sp)
ffffffffc0204708:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020470a:	85aa                	mv	a1,a0
ffffffffc020470c:	8626                	mv	a2,s1
ffffffffc020470e:	854a                	mv	a0,s2
ffffffffc0204710:	4681                	li	a3,0
{
ffffffffc0204712:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204714:	cfcff0ef          	jal	ffffffffc0203c10 <user_mem_check>
ffffffffc0204718:	46050f63          	beqz	a0,ffffffffc0204b96 <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc020471c:	4641                	li	a2,16
ffffffffc020471e:	1808                	addi	a0,sp,48
ffffffffc0204720:	4581                	li	a1,0
ffffffffc0204722:	15c010ef          	jal	ffffffffc020587e <memset>
    if (len > PROC_NAME_LEN)
ffffffffc0204726:	47bd                	li	a5,15
ffffffffc0204728:	8626                	mv	a2,s1
ffffffffc020472a:	0e97ef63          	bltu	a5,s1,ffffffffc0204828 <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc020472e:	85ce                	mv	a1,s3
ffffffffc0204730:	1808                	addi	a0,sp,48
ffffffffc0204732:	15e010ef          	jal	ffffffffc0205890 <memcpy>
    if (mm != NULL)
ffffffffc0204736:	10090063          	beqz	s2,ffffffffc0204836 <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc020473a:	00002517          	auipc	a0,0x2
ffffffffc020473e:	6e650513          	addi	a0,a0,1766 # ffffffffc0206e20 <etext+0x1578>
ffffffffc0204742:	a8dfb0ef          	jal	ffffffffc02001ce <cputs>
ffffffffc0204746:	000b1797          	auipc	a5,0xb1
ffffffffc020474a:	f2a7b783          	ld	a5,-214(a5) # ffffffffc02b5670 <boot_pgdir_pa>
ffffffffc020474e:	577d                	li	a4,-1
ffffffffc0204750:	177e                	slli	a4,a4,0x3f
ffffffffc0204752:	83b1                	srli	a5,a5,0xc
ffffffffc0204754:	8fd9                	or	a5,a5,a4
ffffffffc0204756:	18079073          	csrw	satp,a5
ffffffffc020475a:	03092783          	lw	a5,48(s2)
ffffffffc020475e:	37fd                	addiw	a5,a5,-1
ffffffffc0204760:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204764:	30078563          	beqz	a5,ffffffffc0204a6e <do_execve+0x384>
        current->mm = NULL;
ffffffffc0204768:	000d3783          	ld	a5,0(s10)
ffffffffc020476c:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204770:	e15fe0ef          	jal	ffffffffc0203584 <mm_create>
ffffffffc0204774:	892a                	mv	s2,a0
ffffffffc0204776:	22050063          	beqz	a0,ffffffffc0204996 <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc020477a:	4505                	li	a0,1
ffffffffc020477c:	e42fd0ef          	jal	ffffffffc0201dbe <alloc_pages>
ffffffffc0204780:	42050063          	beqz	a0,ffffffffc0204ba0 <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc0204784:	f0e2                	sd	s8,96(sp)
ffffffffc0204786:	000b1c17          	auipc	s8,0xb1
ffffffffc020478a:	f0ac0c13          	addi	s8,s8,-246 # ffffffffc02b5690 <pages>
ffffffffc020478e:	000c3783          	ld	a5,0(s8)
ffffffffc0204792:	f4de                	sd	s7,104(sp)
ffffffffc0204794:	00004b97          	auipc	s7,0x4
ffffffffc0204798:	984bbb83          	ld	s7,-1660(s7) # ffffffffc0208118 <nbase>
ffffffffc020479c:	40f506b3          	sub	a3,a0,a5
ffffffffc02047a0:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc02047a2:	000b1c97          	auipc	s9,0xb1
ffffffffc02047a6:	ee6c8c93          	addi	s9,s9,-282 # ffffffffc02b5688 <npage>
ffffffffc02047aa:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc02047ac:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02047ae:	5b7d                	li	s6,-1
ffffffffc02047b0:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc02047b4:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02047b6:	00cb5713          	srli	a4,s6,0xc
ffffffffc02047ba:	e83a                	sd	a4,16(sp)
ffffffffc02047bc:	fcd6                	sd	s5,120(sp)
ffffffffc02047be:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02047c0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02047c2:	40f77263          	bgeu	a4,a5,ffffffffc0204bc6 <do_execve+0x4dc>
ffffffffc02047c6:	000b1a97          	auipc	s5,0xb1
ffffffffc02047ca:	ebaa8a93          	addi	s5,s5,-326 # ffffffffc02b5680 <va_pa_offset>
ffffffffc02047ce:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02047d2:	000b1597          	auipc	a1,0xb1
ffffffffc02047d6:	ea65b583          	ld	a1,-346(a1) # ffffffffc02b5678 <boot_pgdir_va>
ffffffffc02047da:	6605                	lui	a2,0x1
ffffffffc02047dc:	00f684b3          	add	s1,a3,a5
ffffffffc02047e0:	8526                	mv	a0,s1
ffffffffc02047e2:	0ae010ef          	jal	ffffffffc0205890 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02047e6:	66e2                	ld	a3,24(sp)
ffffffffc02047e8:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02047ec:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02047f0:	4298                	lw	a4,0(a3)
ffffffffc02047f2:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b903f>
ffffffffc02047f6:	06f70863          	beq	a4,a5,ffffffffc0204866 <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc02047fa:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc02047fc:	854a                	mv	a0,s2
ffffffffc02047fe:	d66ff0ef          	jal	ffffffffc0203d64 <put_pgdir>
ffffffffc0204802:	7ae6                	ld	s5,120(sp)
ffffffffc0204804:	7b46                	ld	s6,112(sp)
ffffffffc0204806:	7ba6                	ld	s7,104(sp)
ffffffffc0204808:	7c06                	ld	s8,96(sp)
ffffffffc020480a:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc020480c:	854a                	mv	a0,s2
ffffffffc020480e:	eb5fe0ef          	jal	ffffffffc02036c2 <mm_destroy>
    do_exit(ret);
ffffffffc0204812:	8526                	mv	a0,s1
ffffffffc0204814:	f122                	sd	s0,160(sp)
ffffffffc0204816:	e152                	sd	s4,128(sp)
ffffffffc0204818:	fcd6                	sd	s5,120(sp)
ffffffffc020481a:	f8da                	sd	s6,112(sp)
ffffffffc020481c:	f4de                	sd	s7,104(sp)
ffffffffc020481e:	f0e2                	sd	s8,96(sp)
ffffffffc0204820:	ece6                	sd	s9,88(sp)
ffffffffc0204822:	e4ee                	sd	s11,72(sp)
ffffffffc0204824:	a7dff0ef          	jal	ffffffffc02042a0 <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204828:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc020482a:	85ce                	mv	a1,s3
ffffffffc020482c:	1808                	addi	a0,sp,48
ffffffffc020482e:	062010ef          	jal	ffffffffc0205890 <memcpy>
    if (mm != NULL)
ffffffffc0204832:	f00914e3          	bnez	s2,ffffffffc020473a <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204836:	000d3783          	ld	a5,0(s10)
ffffffffc020483a:	779c                	ld	a5,40(a5)
ffffffffc020483c:	db95                	beqz	a5,ffffffffc0204770 <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc020483e:	00003617          	auipc	a2,0x3
ffffffffc0204842:	98260613          	addi	a2,a2,-1662 # ffffffffc02071c0 <etext+0x1918>
ffffffffc0204846:	26700593          	li	a1,615
ffffffffc020484a:	00002517          	auipc	a0,0x2
ffffffffc020484e:	7d650513          	addi	a0,a0,2006 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204852:	f122                	sd	s0,160(sp)
ffffffffc0204854:	e152                	sd	s4,128(sp)
ffffffffc0204856:	fcd6                	sd	s5,120(sp)
ffffffffc0204858:	f8da                	sd	s6,112(sp)
ffffffffc020485a:	f4de                	sd	s7,104(sp)
ffffffffc020485c:	f0e2                	sd	s8,96(sp)
ffffffffc020485e:	ece6                	sd	s9,88(sp)
ffffffffc0204860:	e4ee                	sd	s11,72(sp)
ffffffffc0204862:	be9fb0ef          	jal	ffffffffc020044a <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204866:	0386d703          	lhu	a4,56(a3)
ffffffffc020486a:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020486c:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204870:	00371793          	slli	a5,a4,0x3
ffffffffc0204874:	8f99                	sub	a5,a5,a4
ffffffffc0204876:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204878:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020487a:	97d2                	add	a5,a5,s4
ffffffffc020487c:	f122                	sd	s0,160(sp)
ffffffffc020487e:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204880:	00fa7e63          	bgeu	s4,a5,ffffffffc020489c <do_execve+0x1b2>
ffffffffc0204884:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204886:	000a2783          	lw	a5,0(s4)
ffffffffc020488a:	4705                	li	a4,1
ffffffffc020488c:	10e78763          	beq	a5,a4,ffffffffc020499a <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc0204890:	77a2                	ld	a5,40(sp)
ffffffffc0204892:	038a0a13          	addi	s4,s4,56
ffffffffc0204896:	fefa68e3          	bltu	s4,a5,ffffffffc0204886 <do_execve+0x19c>
ffffffffc020489a:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc020489c:	4701                	li	a4,0
ffffffffc020489e:	46ad                	li	a3,11
ffffffffc02048a0:	00100637          	lui	a2,0x100
ffffffffc02048a4:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02048a8:	854a                	mv	a0,s2
ffffffffc02048aa:	e6bfe0ef          	jal	ffffffffc0203714 <mm_map>
ffffffffc02048ae:	84aa                	mv	s1,a0
ffffffffc02048b0:	1a051963          	bnez	a0,ffffffffc0204a62 <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02048b4:	01893503          	ld	a0,24(s2)
ffffffffc02048b8:	467d                	li	a2,31
ffffffffc02048ba:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02048be:	be5fe0ef          	jal	ffffffffc02034a2 <pgdir_alloc_page>
ffffffffc02048c2:	3a050163          	beqz	a0,ffffffffc0204c64 <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048c6:	01893503          	ld	a0,24(s2)
ffffffffc02048ca:	467d                	li	a2,31
ffffffffc02048cc:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02048d0:	bd3fe0ef          	jal	ffffffffc02034a2 <pgdir_alloc_page>
ffffffffc02048d4:	36050763          	beqz	a0,ffffffffc0204c42 <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048d8:	01893503          	ld	a0,24(s2)
ffffffffc02048dc:	467d                	li	a2,31
ffffffffc02048de:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02048e2:	bc1fe0ef          	jal	ffffffffc02034a2 <pgdir_alloc_page>
ffffffffc02048e6:	32050d63          	beqz	a0,ffffffffc0204c20 <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048ea:	01893503          	ld	a0,24(s2)
ffffffffc02048ee:	467d                	li	a2,31
ffffffffc02048f0:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02048f4:	baffe0ef          	jal	ffffffffc02034a2 <pgdir_alloc_page>
ffffffffc02048f8:	30050363          	beqz	a0,ffffffffc0204bfe <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc02048fc:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204900:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204904:	01893683          	ld	a3,24(s2)
ffffffffc0204908:	2785                	addiw	a5,a5,1
ffffffffc020490a:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc020490e:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_matrix_out_size+0xf4ae8>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204912:	c02007b7          	lui	a5,0xc0200
ffffffffc0204916:	2cf6e763          	bltu	a3,a5,ffffffffc0204be4 <do_execve+0x4fa>
ffffffffc020491a:	000ab783          	ld	a5,0(s5)
ffffffffc020491e:	577d                	li	a4,-1
ffffffffc0204920:	177e                	slli	a4,a4,0x3f
ffffffffc0204922:	8e9d                	sub	a3,a3,a5
ffffffffc0204924:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204928:	f654                	sd	a3,168(a2)
ffffffffc020492a:	8fd9                	or	a5,a5,a4
ffffffffc020492c:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204930:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204932:	4581                	li	a1,0
ffffffffc0204934:	12000613          	li	a2,288
ffffffffc0204938:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc020493a:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc020493e:	741000ef          	jal	ffffffffc020587e <memset>
    tf->epc = elf->e_entry; // 设置程序计数器
ffffffffc0204942:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204944:	000d3983          	ld	s3,0(s10)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
ffffffffc0204948:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry; // 设置程序计数器
ffffffffc020494c:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP; // 设置用户栈顶指针
ffffffffc020494e:	4785                	li	a5,1
ffffffffc0204950:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
ffffffffc0204952:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry; // 设置程序计数器
ffffffffc0204956:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP; // 设置用户栈顶指针
ffffffffc020495a:	e81c                	sd	a5,16(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
ffffffffc020495c:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204960:	4641                	li	a2,16
ffffffffc0204962:	4581                	li	a1,0
ffffffffc0204964:	0b498513          	addi	a0,s3,180
ffffffffc0204968:	717000ef          	jal	ffffffffc020587e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020496c:	180c                	addi	a1,sp,48
ffffffffc020496e:	0b498513          	addi	a0,s3,180
ffffffffc0204972:	463d                	li	a2,15
ffffffffc0204974:	71d000ef          	jal	ffffffffc0205890 <memcpy>
ffffffffc0204978:	740a                	ld	s0,160(sp)
ffffffffc020497a:	6a0a                	ld	s4,128(sp)
ffffffffc020497c:	7ae6                	ld	s5,120(sp)
ffffffffc020497e:	7b46                	ld	s6,112(sp)
ffffffffc0204980:	7ba6                	ld	s7,104(sp)
ffffffffc0204982:	7c06                	ld	s8,96(sp)
ffffffffc0204984:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204986:	70aa                	ld	ra,168(sp)
ffffffffc0204988:	694a                	ld	s2,144(sp)
ffffffffc020498a:	69aa                	ld	s3,136(sp)
ffffffffc020498c:	6d46                	ld	s10,80(sp)
ffffffffc020498e:	8526                	mv	a0,s1
ffffffffc0204990:	64ea                	ld	s1,152(sp)
ffffffffc0204992:	614d                	addi	sp,sp,176
ffffffffc0204994:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204996:	54f1                	li	s1,-4
ffffffffc0204998:	bdad                	j	ffffffffc0204812 <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc020499a:	028a3603          	ld	a2,40(s4)
ffffffffc020499e:	020a3783          	ld	a5,32(s4)
ffffffffc02049a2:	20f66363          	bltu	a2,a5,ffffffffc0204ba8 <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc02049a6:	004a2783          	lw	a5,4(s4)
ffffffffc02049aa:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049ae:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc02049b2:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049b4:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049b6:	c6f1                	beqz	a3,ffffffffc0204a82 <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049b8:	1c079763          	bnez	a5,ffffffffc0204b86 <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc02049bc:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc02049be:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc02049c2:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc02049c4:	c709                	beqz	a4,ffffffffc02049ce <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc02049c6:	67a2                	ld	a5,8(sp)
ffffffffc02049c8:	0087e793          	ori	a5,a5,8
ffffffffc02049cc:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc02049ce:	010a3583          	ld	a1,16(s4)
ffffffffc02049d2:	4701                	li	a4,0
ffffffffc02049d4:	854a                	mv	a0,s2
ffffffffc02049d6:	d3ffe0ef          	jal	ffffffffc0203714 <mm_map>
ffffffffc02049da:	84aa                	mv	s1,a0
ffffffffc02049dc:	1c051463          	bnez	a0,ffffffffc0204ba4 <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049e0:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc02049e4:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049e8:	77fd                	lui	a5,0xfffff
ffffffffc02049ea:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc02049ee:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc02049f0:	1a9b7563          	bgeu	s6,s1,ffffffffc0204b9a <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049f4:	008a3983          	ld	s3,8(s4)
ffffffffc02049f8:	67e2                	ld	a5,24(sp)
ffffffffc02049fa:	99be                	add	s3,s3,a5
ffffffffc02049fc:	a881                	j	ffffffffc0204a4c <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc02049fe:	6785                	lui	a5,0x1
ffffffffc0204a00:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204a04:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204a08:	01b4e463          	bltu	s1,s11,ffffffffc0204a10 <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204a0c:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204a10:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204a14:	67c2                	ld	a5,16(sp)
ffffffffc0204a16:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204a1a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204a1e:	8699                	srai	a3,a3,0x6
ffffffffc0204a20:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204a22:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a26:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a28:	18a87363          	bgeu	a6,a0,ffffffffc0204bae <do_execve+0x4c4>
ffffffffc0204a2c:	000ab503          	ld	a0,0(s5)
ffffffffc0204a30:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a34:	e032                	sd	a2,0(sp)
ffffffffc0204a36:	9536                	add	a0,a0,a3
ffffffffc0204a38:	952e                	add	a0,a0,a1
ffffffffc0204a3a:	85ce                	mv	a1,s3
ffffffffc0204a3c:	655000ef          	jal	ffffffffc0205890 <memcpy>
            start += size, from += size;
ffffffffc0204a40:	6602                	ld	a2,0(sp)
ffffffffc0204a42:	9b32                	add	s6,s6,a2
ffffffffc0204a44:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204a46:	049b7563          	bgeu	s6,s1,ffffffffc0204a90 <do_execve+0x3a6>
ffffffffc0204a4a:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204a4c:	01893503          	ld	a0,24(s2)
ffffffffc0204a50:	6622                	ld	a2,8(sp)
ffffffffc0204a52:	e02e                	sd	a1,0(sp)
ffffffffc0204a54:	a4ffe0ef          	jal	ffffffffc02034a2 <pgdir_alloc_page>
ffffffffc0204a58:	6582                	ld	a1,0(sp)
ffffffffc0204a5a:	842a                	mv	s0,a0
ffffffffc0204a5c:	f14d                	bnez	a0,ffffffffc02049fe <do_execve+0x314>
ffffffffc0204a5e:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204a60:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204a62:	854a                	mv	a0,s2
ffffffffc0204a64:	e15fe0ef          	jal	ffffffffc0203878 <exit_mmap>
ffffffffc0204a68:	740a                	ld	s0,160(sp)
ffffffffc0204a6a:	6a0a                	ld	s4,128(sp)
ffffffffc0204a6c:	bb41                	j	ffffffffc02047fc <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204a6e:	854a                	mv	a0,s2
ffffffffc0204a70:	e09fe0ef          	jal	ffffffffc0203878 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204a74:	854a                	mv	a0,s2
ffffffffc0204a76:	aeeff0ef          	jal	ffffffffc0203d64 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204a7a:	854a                	mv	a0,s2
ffffffffc0204a7c:	c47fe0ef          	jal	ffffffffc02036c2 <mm_destroy>
ffffffffc0204a80:	b1e5                	j	ffffffffc0204768 <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a82:	0e078e63          	beqz	a5,ffffffffc0204b7e <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204a86:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204a88:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204a8c:	e43e                	sd	a5,8(sp)
ffffffffc0204a8e:	bf1d                	j	ffffffffc02049c4 <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204a90:	010a3483          	ld	s1,16(s4)
ffffffffc0204a94:	028a3683          	ld	a3,40(s4)
ffffffffc0204a98:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204a9a:	07bb7c63          	bgeu	s6,s11,ffffffffc0204b12 <do_execve+0x428>
            if (start == end)
ffffffffc0204a9e:	df6489e3          	beq	s1,s6,ffffffffc0204890 <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204aa2:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204aa6:	0fb4f563          	bgeu	s1,s11,ffffffffc0204b90 <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204aaa:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204aae:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204ab2:	40d406b3          	sub	a3,s0,a3
ffffffffc0204ab6:	8699                	srai	a3,a3,0x6
ffffffffc0204ab8:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204aba:	00c69593          	slli	a1,a3,0xc
ffffffffc0204abe:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ac0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ac2:	0ec5f663          	bgeu	a1,a2,ffffffffc0204bae <do_execve+0x4c4>
ffffffffc0204ac6:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204aca:	6505                	lui	a0,0x1
ffffffffc0204acc:	955a                	add	a0,a0,s6
ffffffffc0204ace:	96b2                	add	a3,a3,a2
ffffffffc0204ad0:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ad4:	9536                	add	a0,a0,a3
ffffffffc0204ad6:	864e                	mv	a2,s3
ffffffffc0204ad8:	4581                	li	a1,0
ffffffffc0204ada:	5a5000ef          	jal	ffffffffc020587e <memset>
            start += size;
ffffffffc0204ade:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204ae0:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204ae4:	01b4f463          	bgeu	s1,s11,ffffffffc0204aec <do_execve+0x402>
ffffffffc0204ae8:	db6484e3          	beq	s1,s6,ffffffffc0204890 <do_execve+0x1a6>
ffffffffc0204aec:	e299                	bnez	a3,ffffffffc0204af2 <do_execve+0x408>
ffffffffc0204aee:	03bb0263          	beq	s6,s11,ffffffffc0204b12 <do_execve+0x428>
ffffffffc0204af2:	00002697          	auipc	a3,0x2
ffffffffc0204af6:	6f668693          	addi	a3,a3,1782 # ffffffffc02071e8 <etext+0x1940>
ffffffffc0204afa:	00001617          	auipc	a2,0x1
ffffffffc0204afe:	78e60613          	addi	a2,a2,1934 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0204b02:	2d000593          	li	a1,720
ffffffffc0204b06:	00002517          	auipc	a0,0x2
ffffffffc0204b0a:	51a50513          	addi	a0,a0,1306 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204b0e:	93dfb0ef          	jal	ffffffffc020044a <__panic>
        while (start < end)
ffffffffc0204b12:	d69b7fe3          	bgeu	s6,s1,ffffffffc0204890 <do_execve+0x1a6>
ffffffffc0204b16:	56fd                	li	a3,-1
ffffffffc0204b18:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b1c:	f03e                	sd	a5,32(sp)
ffffffffc0204b1e:	a0b9                	j	ffffffffc0204b6c <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b20:	6785                	lui	a5,0x1
ffffffffc0204b22:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204b26:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204b2a:	0104e463          	bltu	s1,a6,ffffffffc0204b32 <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b2e:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204b32:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204b36:	7782                	ld	a5,32(sp)
ffffffffc0204b38:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204b3c:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b40:	8699                	srai	a3,a3,0x6
ffffffffc0204b42:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204b44:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b48:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b4a:	06b57263          	bgeu	a0,a1,ffffffffc0204bae <do_execve+0x4c4>
ffffffffc0204b4e:	000ab583          	ld	a1,0(s5)
ffffffffc0204b52:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b56:	864e                	mv	a2,s3
ffffffffc0204b58:	96ae                	add	a3,a3,a1
ffffffffc0204b5a:	9536                	add	a0,a0,a3
ffffffffc0204b5c:	4581                	li	a1,0
            start += size;
ffffffffc0204b5e:	9b4e                	add	s6,s6,s3
ffffffffc0204b60:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b62:	51d000ef          	jal	ffffffffc020587e <memset>
        while (start < end)
ffffffffc0204b66:	d29b75e3          	bgeu	s6,s1,ffffffffc0204890 <do_execve+0x1a6>
ffffffffc0204b6a:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b6c:	01893503          	ld	a0,24(s2)
ffffffffc0204b70:	6622                	ld	a2,8(sp)
ffffffffc0204b72:	85ee                	mv	a1,s11
ffffffffc0204b74:	92ffe0ef          	jal	ffffffffc02034a2 <pgdir_alloc_page>
ffffffffc0204b78:	842a                	mv	s0,a0
ffffffffc0204b7a:	f15d                	bnez	a0,ffffffffc0204b20 <do_execve+0x436>
ffffffffc0204b7c:	b5cd                	j	ffffffffc0204a5e <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204b7e:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b80:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204b82:	e43e                	sd	a5,8(sp)
ffffffffc0204b84:	b581                	j	ffffffffc02049c4 <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204b86:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204b88:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204b8c:	e43e                	sd	a5,8(sp)
ffffffffc0204b8e:	bd1d                	j	ffffffffc02049c4 <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204b90:	416d89b3          	sub	s3,s11,s6
ffffffffc0204b94:	bf19                	j	ffffffffc0204aaa <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204b96:	54f5                	li	s1,-3
ffffffffc0204b98:	b3fd                	j	ffffffffc0204986 <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b9a:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204b9c:	84da                	mv	s1,s6
ffffffffc0204b9e:	bddd                	j	ffffffffc0204a94 <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204ba0:	54f1                	li	s1,-4
ffffffffc0204ba2:	b1ad                	j	ffffffffc020480c <do_execve+0x122>
ffffffffc0204ba4:	6da6                	ld	s11,72(sp)
ffffffffc0204ba6:	bd75                	j	ffffffffc0204a62 <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204ba8:	6da6                	ld	s11,72(sp)
ffffffffc0204baa:	54e1                	li	s1,-8
ffffffffc0204bac:	bd5d                	j	ffffffffc0204a62 <do_execve+0x378>
ffffffffc0204bae:	00002617          	auipc	a2,0x2
ffffffffc0204bb2:	a8a60613          	addi	a2,a2,-1398 # ffffffffc0206638 <etext+0xd90>
ffffffffc0204bb6:	07100593          	li	a1,113
ffffffffc0204bba:	00002517          	auipc	a0,0x2
ffffffffc0204bbe:	aa650513          	addi	a0,a0,-1370 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0204bc2:	889fb0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0204bc6:	00002617          	auipc	a2,0x2
ffffffffc0204bca:	a7260613          	addi	a2,a2,-1422 # ffffffffc0206638 <etext+0xd90>
ffffffffc0204bce:	07100593          	li	a1,113
ffffffffc0204bd2:	00002517          	auipc	a0,0x2
ffffffffc0204bd6:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0206660 <etext+0xdb8>
ffffffffc0204bda:	f122                	sd	s0,160(sp)
ffffffffc0204bdc:	e152                	sd	s4,128(sp)
ffffffffc0204bde:	e4ee                	sd	s11,72(sp)
ffffffffc0204be0:	86bfb0ef          	jal	ffffffffc020044a <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204be4:	00002617          	auipc	a2,0x2
ffffffffc0204be8:	afc60613          	addi	a2,a2,-1284 # ffffffffc02066e0 <etext+0xe38>
ffffffffc0204bec:	2ef00593          	li	a1,751
ffffffffc0204bf0:	00002517          	auipc	a0,0x2
ffffffffc0204bf4:	43050513          	addi	a0,a0,1072 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204bf8:	e4ee                	sd	s11,72(sp)
ffffffffc0204bfa:	851fb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bfe:	00002697          	auipc	a3,0x2
ffffffffc0204c02:	70268693          	addi	a3,a3,1794 # ffffffffc0207300 <etext+0x1a58>
ffffffffc0204c06:	00001617          	auipc	a2,0x1
ffffffffc0204c0a:	68260613          	addi	a2,a2,1666 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0204c0e:	2ea00593          	li	a1,746
ffffffffc0204c12:	00002517          	auipc	a0,0x2
ffffffffc0204c16:	40e50513          	addi	a0,a0,1038 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204c1a:	e4ee                	sd	s11,72(sp)
ffffffffc0204c1c:	82ffb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c20:	00002697          	auipc	a3,0x2
ffffffffc0204c24:	69868693          	addi	a3,a3,1688 # ffffffffc02072b8 <etext+0x1a10>
ffffffffc0204c28:	00001617          	auipc	a2,0x1
ffffffffc0204c2c:	66060613          	addi	a2,a2,1632 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0204c30:	2e900593          	li	a1,745
ffffffffc0204c34:	00002517          	auipc	a0,0x2
ffffffffc0204c38:	3ec50513          	addi	a0,a0,1004 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204c3c:	e4ee                	sd	s11,72(sp)
ffffffffc0204c3e:	80dfb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c42:	00002697          	auipc	a3,0x2
ffffffffc0204c46:	62e68693          	addi	a3,a3,1582 # ffffffffc0207270 <etext+0x19c8>
ffffffffc0204c4a:	00001617          	auipc	a2,0x1
ffffffffc0204c4e:	63e60613          	addi	a2,a2,1598 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0204c52:	2e800593          	li	a1,744
ffffffffc0204c56:	00002517          	auipc	a0,0x2
ffffffffc0204c5a:	3ca50513          	addi	a0,a0,970 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204c5e:	e4ee                	sd	s11,72(sp)
ffffffffc0204c60:	feafb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204c64:	00002697          	auipc	a3,0x2
ffffffffc0204c68:	5c468693          	addi	a3,a3,1476 # ffffffffc0207228 <etext+0x1980>
ffffffffc0204c6c:	00001617          	auipc	a2,0x1
ffffffffc0204c70:	61c60613          	addi	a2,a2,1564 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0204c74:	2e700593          	li	a1,743
ffffffffc0204c78:	00002517          	auipc	a0,0x2
ffffffffc0204c7c:	3a850513          	addi	a0,a0,936 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204c80:	e4ee                	sd	s11,72(sp)
ffffffffc0204c82:	fc8fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204c86 <user_main>:
{
ffffffffc0204c86:	1101                	addi	sp,sp,-32
ffffffffc0204c88:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204c8a:	000b1497          	auipc	s1,0xb1
ffffffffc0204c8e:	a1648493          	addi	s1,s1,-1514 # ffffffffc02b56a0 <current>
ffffffffc0204c92:	609c                	ld	a5,0(s1)
ffffffffc0204c94:	00002617          	auipc	a2,0x2
ffffffffc0204c98:	6b460613          	addi	a2,a2,1716 # ffffffffc0207348 <etext+0x1aa0>
ffffffffc0204c9c:	00002517          	auipc	a0,0x2
ffffffffc0204ca0:	6bc50513          	addi	a0,a0,1724 # ffffffffc0207358 <etext+0x1ab0>
ffffffffc0204ca4:	43cc                	lw	a1,4(a5)
{
ffffffffc0204ca6:	ec06                	sd	ra,24(sp)
ffffffffc0204ca8:	e822                	sd	s0,16(sp)
ffffffffc0204caa:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204cac:	cecfb0ef          	jal	ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204cb0:	00002517          	auipc	a0,0x2
ffffffffc0204cb4:	69850513          	addi	a0,a0,1688 # ffffffffc0207348 <etext+0x1aa0>
ffffffffc0204cb8:	313000ef          	jal	ffffffffc02057ca <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204cbc:	6098                	ld	a4,0(s1)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204cbe:	6789                	lui	a5,0x2
ffffffffc0204cc0:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7048>
ffffffffc0204cc4:	6b00                	ld	s0,16(a4)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204cc6:	734c                	ld	a1,160(a4)
    size_t len = strlen(name);
ffffffffc0204cc8:	892a                	mv	s2,a0
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204cca:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204ccc:	12000613          	li	a2,288
ffffffffc0204cd0:	8522                	mv	a0,s0
ffffffffc0204cd2:	3bf000ef          	jal	ffffffffc0205890 <memcpy>
    current->tf = new_tf;
ffffffffc0204cd6:	609c                	ld	a5,0(s1)
    ret = do_execve(name, len, binary, size);
ffffffffc0204cd8:	85ca                	mv	a1,s2
ffffffffc0204cda:	3fe06697          	auipc	a3,0x3fe06
ffffffffc0204cde:	a3e68693          	addi	a3,a3,-1474 # a718 <_binary_obj___user_priority_out_size>
    current->tf = new_tf;
ffffffffc0204ce2:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204ce4:	00072617          	auipc	a2,0x72
ffffffffc0204ce8:	cac60613          	addi	a2,a2,-852 # ffffffffc0276990 <_binary_obj___user_priority_out_start>
ffffffffc0204cec:	00002517          	auipc	a0,0x2
ffffffffc0204cf0:	65c50513          	addi	a0,a0,1628 # ffffffffc0207348 <etext+0x1aa0>
ffffffffc0204cf4:	9f7ff0ef          	jal	ffffffffc02046ea <do_execve>
    asm volatile(
ffffffffc0204cf8:	8122                	mv	sp,s0
ffffffffc0204cfa:	936fc06f          	j	ffffffffc0200e30 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204cfe:	00002617          	auipc	a2,0x2
ffffffffc0204d02:	68260613          	addi	a2,a2,1666 # ffffffffc0207380 <etext+0x1ad8>
ffffffffc0204d06:	3d200593          	li	a1,978
ffffffffc0204d0a:	00002517          	auipc	a0,0x2
ffffffffc0204d0e:	31650513          	addi	a0,a0,790 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204d12:	f38fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204d16 <do_yield>:
    current->need_resched = 1;
ffffffffc0204d16:	000b1797          	auipc	a5,0xb1
ffffffffc0204d1a:	98a7b783          	ld	a5,-1654(a5) # ffffffffc02b56a0 <current>
ffffffffc0204d1e:	4705                	li	a4,1
}
ffffffffc0204d20:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204d22:	ef98                	sd	a4,24(a5)
}
ffffffffc0204d24:	8082                	ret

ffffffffc0204d26 <do_wait>:
    if (code_store != NULL)
ffffffffc0204d26:	c59d                	beqz	a1,ffffffffc0204d54 <do_wait+0x2e>
{
ffffffffc0204d28:	1101                	addi	sp,sp,-32
ffffffffc0204d2a:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204d2c:	000b1517          	auipc	a0,0xb1
ffffffffc0204d30:	97453503          	ld	a0,-1676(a0) # ffffffffc02b56a0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d34:	4685                	li	a3,1
ffffffffc0204d36:	4611                	li	a2,4
ffffffffc0204d38:	7508                	ld	a0,40(a0)
{
ffffffffc0204d3a:	ec06                	sd	ra,24(sp)
ffffffffc0204d3c:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d3e:	ed3fe0ef          	jal	ffffffffc0203c10 <user_mem_check>
ffffffffc0204d42:	6702                	ld	a4,0(sp)
ffffffffc0204d44:	67a2                	ld	a5,8(sp)
ffffffffc0204d46:	c909                	beqz	a0,ffffffffc0204d58 <do_wait+0x32>
}
ffffffffc0204d48:	60e2                	ld	ra,24(sp)
ffffffffc0204d4a:	85be                	mv	a1,a5
ffffffffc0204d4c:	853a                	mv	a0,a4
ffffffffc0204d4e:	6105                	addi	sp,sp,32
ffffffffc0204d50:	e94ff06f          	j	ffffffffc02043e4 <do_wait.part.0>
ffffffffc0204d54:	e90ff06f          	j	ffffffffc02043e4 <do_wait.part.0>
ffffffffc0204d58:	60e2                	ld	ra,24(sp)
ffffffffc0204d5a:	5575                	li	a0,-3
ffffffffc0204d5c:	6105                	addi	sp,sp,32
ffffffffc0204d5e:	8082                	ret

ffffffffc0204d60 <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d60:	6789                	lui	a5,0x2
ffffffffc0204d62:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d66:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f2a>
ffffffffc0204d68:	06e7e463          	bltu	a5,a4,ffffffffc0204dd0 <do_kill+0x70>
{
ffffffffc0204d6c:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d6e:	45a9                	li	a1,10
{
ffffffffc0204d70:	ec06                	sd	ra,24(sp)
ffffffffc0204d72:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d74:	674000ef          	jal	ffffffffc02053e8 <hash32>
ffffffffc0204d78:	02051793          	slli	a5,a0,0x20
ffffffffc0204d7c:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204d80:	000ad797          	auipc	a5,0xad
ffffffffc0204d84:	88078793          	addi	a5,a5,-1920 # ffffffffc02b1600 <hash_list>
ffffffffc0204d88:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204d8a:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d8c:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204d8e:	a029                	j	ffffffffc0204d98 <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204d90:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204d94:	00c70963          	beq	a4,a2,ffffffffc0204da6 <do_kill+0x46>
ffffffffc0204d98:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204d9a:	fea69be3          	bne	a3,a0,ffffffffc0204d90 <do_kill+0x30>
}
ffffffffc0204d9e:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204da0:	5575                	li	a0,-3
}
ffffffffc0204da2:	6105                	addi	sp,sp,32
ffffffffc0204da4:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204da6:	fd852703          	lw	a4,-40(a0)
ffffffffc0204daa:	00177693          	andi	a3,a4,1
ffffffffc0204dae:	e29d                	bnez	a3,ffffffffc0204dd4 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204db0:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204db2:	00176713          	ori	a4,a4,1
ffffffffc0204db6:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204dba:	0006c663          	bltz	a3,ffffffffc0204dc6 <do_kill+0x66>
            return 0;
ffffffffc0204dbe:	4501                	li	a0,0
}
ffffffffc0204dc0:	60e2                	ld	ra,24(sp)
ffffffffc0204dc2:	6105                	addi	sp,sp,32
ffffffffc0204dc4:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204dc6:	f2850513          	addi	a0,a0,-216
ffffffffc0204dca:	374000ef          	jal	ffffffffc020513e <wakeup_proc>
ffffffffc0204dce:	bfc5                	j	ffffffffc0204dbe <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204dd0:	5575                	li	a0,-3
}
ffffffffc0204dd2:	8082                	ret
        return -E_KILLED;
ffffffffc0204dd4:	555d                	li	a0,-9
ffffffffc0204dd6:	b7ed                	j	ffffffffc0204dc0 <do_kill+0x60>

ffffffffc0204dd8 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204dd8:	1101                	addi	sp,sp,-32
ffffffffc0204dda:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204ddc:	000b1797          	auipc	a5,0xb1
ffffffffc0204de0:	82478793          	addi	a5,a5,-2012 # ffffffffc02b5600 <proc_list>
ffffffffc0204de4:	ec06                	sd	ra,24(sp)
ffffffffc0204de6:	e822                	sd	s0,16(sp)
ffffffffc0204de8:	e04a                	sd	s2,0(sp)
ffffffffc0204dea:	000ad497          	auipc	s1,0xad
ffffffffc0204dee:	81648493          	addi	s1,s1,-2026 # ffffffffc02b1600 <hash_list>
ffffffffc0204df2:	e79c                	sd	a5,8(a5)
ffffffffc0204df4:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204df6:	000b1717          	auipc	a4,0xb1
ffffffffc0204dfa:	80a70713          	addi	a4,a4,-2038 # ffffffffc02b5600 <proc_list>
ffffffffc0204dfe:	87a6                	mv	a5,s1
ffffffffc0204e00:	e79c                	sd	a5,8(a5)
ffffffffc0204e02:	e39c                	sd	a5,0(a5)
ffffffffc0204e04:	07c1                	addi	a5,a5,16
ffffffffc0204e06:	fee79de3          	bne	a5,a4,ffffffffc0204e00 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204e0a:	eb3fe0ef          	jal	ffffffffc0203cbc <alloc_proc>
ffffffffc0204e0e:	000b1917          	auipc	s2,0xb1
ffffffffc0204e12:	8a290913          	addi	s2,s2,-1886 # ffffffffc02b56b0 <idleproc>
ffffffffc0204e16:	00a93023          	sd	a0,0(s2)
ffffffffc0204e1a:	10050363          	beqz	a0,ffffffffc0204f20 <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204e1e:	4789                	li	a5,2
ffffffffc0204e20:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e22:	00004797          	auipc	a5,0x4
ffffffffc0204e26:	1de78793          	addi	a5,a5,478 # ffffffffc0209000 <bootstack>
ffffffffc0204e2a:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e2c:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0204e30:	4785                	li	a5,1
ffffffffc0204e32:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e34:	4641                	li	a2,16
ffffffffc0204e36:	8522                	mv	a0,s0
ffffffffc0204e38:	4581                	li	a1,0
ffffffffc0204e3a:	245000ef          	jal	ffffffffc020587e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e3e:	8522                	mv	a0,s0
ffffffffc0204e40:	463d                	li	a2,15
ffffffffc0204e42:	00002597          	auipc	a1,0x2
ffffffffc0204e46:	57658593          	addi	a1,a1,1398 # ffffffffc02073b8 <etext+0x1b10>
ffffffffc0204e4a:	247000ef          	jal	ffffffffc0205890 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204e4e:	000b1797          	auipc	a5,0xb1
ffffffffc0204e52:	84a7a783          	lw	a5,-1974(a5) # ffffffffc02b5698 <nr_process>

    current = idleproc;
ffffffffc0204e56:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e5a:	4601                	li	a2,0
    nr_process++;
ffffffffc0204e5c:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e5e:	4581                	li	a1,0
ffffffffc0204e60:	fffff517          	auipc	a0,0xfffff
ffffffffc0204e64:	76650513          	addi	a0,a0,1894 # ffffffffc02045c6 <init_main>
    current = idleproc;
ffffffffc0204e68:	000b1697          	auipc	a3,0xb1
ffffffffc0204e6c:	82e6bc23          	sd	a4,-1992(a3) # ffffffffc02b56a0 <current>
    nr_process++;
ffffffffc0204e70:	000b1717          	auipc	a4,0xb1
ffffffffc0204e74:	82f72423          	sw	a5,-2008(a4) # ffffffffc02b5698 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e78:	bd8ff0ef          	jal	ffffffffc0204250 <kernel_thread>
ffffffffc0204e7c:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204e7e:	08a05563          	blez	a0,ffffffffc0204f08 <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e82:	6789                	lui	a5,0x2
ffffffffc0204e84:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f2a>
ffffffffc0204e86:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e8a:	02e7e463          	bltu	a5,a4,ffffffffc0204eb2 <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e8e:	45a9                	li	a1,10
ffffffffc0204e90:	558000ef          	jal	ffffffffc02053e8 <hash32>
ffffffffc0204e94:	02051713          	slli	a4,a0,0x20
ffffffffc0204e98:	01c75793          	srli	a5,a4,0x1c
ffffffffc0204e9c:	00f486b3          	add	a3,s1,a5
ffffffffc0204ea0:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204ea2:	a029                	j	ffffffffc0204eac <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc0204ea4:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204ea8:	04870d63          	beq	a4,s0,ffffffffc0204f02 <proc_init+0x12a>
    return listelm->next;
ffffffffc0204eac:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204eae:	fef69be3          	bne	a3,a5,ffffffffc0204ea4 <proc_init+0xcc>
    return NULL;
ffffffffc0204eb2:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204eb4:	0b478413          	addi	s0,a5,180
ffffffffc0204eb8:	4641                	li	a2,16
ffffffffc0204eba:	4581                	li	a1,0
ffffffffc0204ebc:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204ebe:	000b0717          	auipc	a4,0xb0
ffffffffc0204ec2:	7ef73523          	sd	a5,2026(a4) # ffffffffc02b56a8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ec6:	1b9000ef          	jal	ffffffffc020587e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204eca:	8522                	mv	a0,s0
ffffffffc0204ecc:	463d                	li	a2,15
ffffffffc0204ece:	00002597          	auipc	a1,0x2
ffffffffc0204ed2:	51258593          	addi	a1,a1,1298 # ffffffffc02073e0 <etext+0x1b38>
ffffffffc0204ed6:	1bb000ef          	jal	ffffffffc0205890 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204eda:	00093783          	ld	a5,0(s2)
ffffffffc0204ede:	cfad                	beqz	a5,ffffffffc0204f58 <proc_init+0x180>
ffffffffc0204ee0:	43dc                	lw	a5,4(a5)
ffffffffc0204ee2:	ebbd                	bnez	a5,ffffffffc0204f58 <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204ee4:	000b0797          	auipc	a5,0xb0
ffffffffc0204ee8:	7c47b783          	ld	a5,1988(a5) # ffffffffc02b56a8 <initproc>
ffffffffc0204eec:	c7b1                	beqz	a5,ffffffffc0204f38 <proc_init+0x160>
ffffffffc0204eee:	43d8                	lw	a4,4(a5)
ffffffffc0204ef0:	4785                	li	a5,1
ffffffffc0204ef2:	04f71363          	bne	a4,a5,ffffffffc0204f38 <proc_init+0x160>
}
ffffffffc0204ef6:	60e2                	ld	ra,24(sp)
ffffffffc0204ef8:	6442                	ld	s0,16(sp)
ffffffffc0204efa:	64a2                	ld	s1,8(sp)
ffffffffc0204efc:	6902                	ld	s2,0(sp)
ffffffffc0204efe:	6105                	addi	sp,sp,32
ffffffffc0204f00:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204f02:	f2878793          	addi	a5,a5,-216
ffffffffc0204f06:	b77d                	j	ffffffffc0204eb4 <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc0204f08:	00002617          	auipc	a2,0x2
ffffffffc0204f0c:	4b860613          	addi	a2,a2,1208 # ffffffffc02073c0 <etext+0x1b18>
ffffffffc0204f10:	40e00593          	li	a1,1038
ffffffffc0204f14:	00002517          	auipc	a0,0x2
ffffffffc0204f18:	10c50513          	addi	a0,a0,268 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204f1c:	d2efb0ef          	jal	ffffffffc020044a <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204f20:	00002617          	auipc	a2,0x2
ffffffffc0204f24:	48060613          	addi	a2,a2,1152 # ffffffffc02073a0 <etext+0x1af8>
ffffffffc0204f28:	3ff00593          	li	a1,1023
ffffffffc0204f2c:	00002517          	auipc	a0,0x2
ffffffffc0204f30:	0f450513          	addi	a0,a0,244 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204f34:	d16fb0ef          	jal	ffffffffc020044a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f38:	00002697          	auipc	a3,0x2
ffffffffc0204f3c:	4d868693          	addi	a3,a3,1240 # ffffffffc0207410 <etext+0x1b68>
ffffffffc0204f40:	00001617          	auipc	a2,0x1
ffffffffc0204f44:	34860613          	addi	a2,a2,840 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0204f48:	41500593          	li	a1,1045
ffffffffc0204f4c:	00002517          	auipc	a0,0x2
ffffffffc0204f50:	0d450513          	addi	a0,a0,212 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204f54:	cf6fb0ef          	jal	ffffffffc020044a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f58:	00002697          	auipc	a3,0x2
ffffffffc0204f5c:	49068693          	addi	a3,a3,1168 # ffffffffc02073e8 <etext+0x1b40>
ffffffffc0204f60:	00001617          	auipc	a2,0x1
ffffffffc0204f64:	32860613          	addi	a2,a2,808 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0204f68:	41400593          	li	a1,1044
ffffffffc0204f6c:	00002517          	auipc	a0,0x2
ffffffffc0204f70:	0b450513          	addi	a0,a0,180 # ffffffffc0207020 <etext+0x1778>
ffffffffc0204f74:	cd6fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204f78 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204f78:	1141                	addi	sp,sp,-16
ffffffffc0204f7a:	e022                	sd	s0,0(sp)
ffffffffc0204f7c:	e406                	sd	ra,8(sp)
ffffffffc0204f7e:	000b0417          	auipc	s0,0xb0
ffffffffc0204f82:	72240413          	addi	s0,s0,1826 # ffffffffc02b56a0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204f86:	6018                	ld	a4,0(s0)
ffffffffc0204f88:	6f1c                	ld	a5,24(a4)
ffffffffc0204f8a:	dffd                	beqz	a5,ffffffffc0204f88 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204f8c:	2aa000ef          	jal	ffffffffc0205236 <schedule>
ffffffffc0204f90:	bfdd                	j	ffffffffc0204f86 <cpu_idle+0xe>

ffffffffc0204f92 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0204f92:	1101                	addi	sp,sp,-32
ffffffffc0204f94:	85aa                	mv	a1,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0204f96:	e42a                	sd	a0,8(sp)
ffffffffc0204f98:	00002517          	auipc	a0,0x2
ffffffffc0204f9c:	4a050513          	addi	a0,a0,1184 # ffffffffc0207438 <etext+0x1b90>
{
ffffffffc0204fa0:	ec06                	sd	ra,24(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204fa2:	9f6fb0ef          	jal	ffffffffc0200198 <cprintf>
    if (priority == 0)
ffffffffc0204fa6:	65a2                	ld	a1,8(sp)
        current->lab6_priority = 1;
ffffffffc0204fa8:	000b0717          	auipc	a4,0xb0
ffffffffc0204fac:	6f873703          	ld	a4,1784(a4) # ffffffffc02b56a0 <current>
    if (priority == 0)
ffffffffc0204fb0:	4785                	li	a5,1
ffffffffc0204fb2:	c191                	beqz	a1,ffffffffc0204fb6 <lab6_set_priority+0x24>
ffffffffc0204fb4:	87ae                	mv	a5,a1
    else
        current->lab6_priority = priority;
}
ffffffffc0204fb6:	60e2                	ld	ra,24(sp)
        current->lab6_priority = 1;
ffffffffc0204fb8:	14f72223          	sw	a5,324(a4)
}
ffffffffc0204fbc:	6105                	addi	sp,sp,32
ffffffffc0204fbe:	8082                	ret

ffffffffc0204fc0 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204fc0:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204fc4:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204fc8:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204fca:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204fcc:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204fd0:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204fd4:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204fd8:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204fdc:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204fe0:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204fe4:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204fe8:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204fec:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204ff0:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204ff4:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204ff8:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204ffc:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204ffe:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205000:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205004:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205008:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020500c:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205010:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205014:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205018:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020501c:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205020:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205024:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205028:	8082                	ret

ffffffffc020502a <RR_init>:
    elm->prev = elm->next = elm;
ffffffffc020502a:	e508                	sd	a0,8(a0)
ffffffffc020502c:	e108                	sd	a0,0(a0)
static void
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_init(&(rq->run_list)); // 把 rq->run_list 初始化为空双向循环链表头
    rq->proc_num = 0; // 把运行队列中的进程计数器置 0，表示当前队列无进程
ffffffffc020502e:	00052823          	sw	zero,16(a0)
}
ffffffffc0205032:	8082                	ret

ffffffffc0205034 <RR_dequeue>:
    return list->next == list;
ffffffffc0205034:	1185b703          	ld	a4,280(a1)
 */
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    if(!list_empty(&(proc->run_link)) && proc->rq == rq){ // proc->run_link 非空并且 proc 所属的 rq 是传入的 rq
ffffffffc0205038:	11058793          	addi	a5,a1,272
ffffffffc020503c:	00e78663          	beq	a5,a4,ffffffffc0205048 <RR_dequeue+0x14>
ffffffffc0205040:	1085b683          	ld	a3,264(a1)
ffffffffc0205044:	00a68363          	beq	a3,a0,ffffffffc020504a <RR_dequeue+0x16>
        list_del_init(&(proc->run_link)); // 从链表中删除 proc->run_link，并把该结点重置为链表初始状态
        rq->proc_num --;
    }
}
ffffffffc0205048:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc020504a:	1105b503          	ld	a0,272(a1)
        rq->proc_num --;
ffffffffc020504e:	4a90                	lw	a2,16(a3)
    prev->next = next;
ffffffffc0205050:	e518                	sd	a4,8(a0)
    next->prev = prev;
ffffffffc0205052:	e308                	sd	a0,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0205054:	10f5bc23          	sd	a5,280(a1)
ffffffffc0205058:	10f5b823          	sd	a5,272(a1)
ffffffffc020505c:	367d                	addiw	a2,a2,-1
ffffffffc020505e:	ca90                	sw	a2,16(a3)
}
ffffffffc0205060:	8082                	ret

ffffffffc0205062 <RR_pick_next>:
    return listelm->next;
ffffffffc0205062:	651c                	ld	a5,8(a0)
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_entry_t *le = list_next(&(rq->run_list)); // 获取运行队列中第一个进程的链表结点
    if (le != &(rq->run_list)) { // 不能是头部本身
ffffffffc0205064:	00f50563          	beq	a0,a5,ffffffffc020506e <RR_pick_next+0xc>
        return le2proc(le, run_link); // 用 le2proc 宏把链表结点转换为对应的 proc_struct 指针并返回
ffffffffc0205068:	ef078513          	addi	a0,a5,-272
ffffffffc020506c:	8082                	ret
    }
    return NULL;
ffffffffc020506e:	4501                	li	a0,0
}
ffffffffc0205070:	8082                	ret

ffffffffc0205072 <RR_proc_tick>:
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{ // 此函数在当前进程的时钟滴答事件触发时被调用，应减少 proc->time_slice 并在耗尽时将进程的需要重新调度标志置为 1
    // LAB6: YOUR CODE
    if (proc->time_slice > 0) {
ffffffffc0205072:	1205a783          	lw	a5,288(a1)
ffffffffc0205076:	00f05563          	blez	a5,ffffffffc0205080 <RR_proc_tick+0xe>
        proc->time_slice --;
ffffffffc020507a:	37fd                	addiw	a5,a5,-1
ffffffffc020507c:	12f5a023          	sw	a5,288(a1)
    }
    if (proc->time_slice == 0) {
ffffffffc0205080:	e399                	bnez	a5,ffffffffc0205086 <RR_proc_tick+0x14>
        proc->need_resched = 1;
ffffffffc0205082:	4785                	li	a5,1
ffffffffc0205084:	ed9c                	sd	a5,24(a1)
    }
}
ffffffffc0205086:	8082                	ret

ffffffffc0205088 <RR_enqueue>:
    if(list_empty(&(proc->run_link))){ // 当 proc 的 run_link 链表结点为空时
ffffffffc0205088:	1185b703          	ld	a4,280(a1)
ffffffffc020508c:	11058793          	addi	a5,a1,272
ffffffffc0205090:	00e78363          	beq	a5,a4,ffffffffc0205096 <RR_enqueue+0xe>
}
ffffffffc0205094:	8082                	ret
    __list_add(elm, listelm->prev, listelm);
ffffffffc0205096:	6118                	ld	a4,0(a0)
        if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) { // 检查 proc 当前 time_slice 是否未初始化（0）或超过队列允许的最大时间片
ffffffffc0205098:	1205a683          	lw	a3,288(a1)
    prev->next = next->prev = elm;
ffffffffc020509c:	e11c                	sd	a5,0(a0)
ffffffffc020509e:	e71c                	sd	a5,8(a4)
    elm->prev = prev;
ffffffffc02050a0:	10e5b823          	sd	a4,272(a1)
    elm->next = next;
ffffffffc02050a4:	10a5bc23          	sd	a0,280(a1)
ffffffffc02050a8:	495c                	lw	a5,20(a0)
ffffffffc02050aa:	ea89                	bnez	a3,ffffffffc02050bc <RR_enqueue+0x34>
            proc->time_slice = rq->max_time_slice; // 分配时间片
ffffffffc02050ac:	12f5a023          	sw	a5,288(a1)
        rq->proc_num ++;
ffffffffc02050b0:	491c                	lw	a5,16(a0)
        proc->rq = rq; // 把 proc 的 rq 指针设置为当前运行队列
ffffffffc02050b2:	10a5b423          	sd	a0,264(a1)
        rq->proc_num ++;
ffffffffc02050b6:	2785                	addiw	a5,a5,1
ffffffffc02050b8:	c91c                	sw	a5,16(a0)
}
ffffffffc02050ba:	8082                	ret
        if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) { // 检查 proc 当前 time_slice 是否未初始化（0）或超过队列允许的最大时间片
ffffffffc02050bc:	fed7dae3          	bge	a5,a3,ffffffffc02050b0 <RR_enqueue+0x28>
ffffffffc02050c0:	b7f5                	j	ffffffffc02050ac <RR_enqueue+0x24>

ffffffffc02050c2 <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc02050c2:	000b0797          	auipc	a5,0xb0
ffffffffc02050c6:	5ee7b783          	ld	a5,1518(a5) # ffffffffc02b56b0 <idleproc>
{
ffffffffc02050ca:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc02050cc:	00a78c63          	beq	a5,a0,ffffffffc02050e4 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc02050d0:	000b0797          	auipc	a5,0xb0
ffffffffc02050d4:	5f07b783          	ld	a5,1520(a5) # ffffffffc02b56c0 <sched_class>
ffffffffc02050d8:	000b0517          	auipc	a0,0xb0
ffffffffc02050dc:	5e053503          	ld	a0,1504(a0) # ffffffffc02b56b8 <rq>
ffffffffc02050e0:	779c                	ld	a5,40(a5)
ffffffffc02050e2:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc02050e4:	4705                	li	a4,1
ffffffffc02050e6:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc02050e8:	8082                	ret

ffffffffc02050ea <sched_init>:

void sched_init(void)
{
    list_init(&timer_list);

    sched_class = &default_sched_class;
ffffffffc02050ea:	000ac797          	auipc	a5,0xac
ffffffffc02050ee:	0be78793          	addi	a5,a5,190 # ffffffffc02b11a8 <default_sched_class>
{
ffffffffc02050f2:	1141                	addi	sp,sp,-16

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc02050f4:	6794                	ld	a3,8(a5)
    sched_class = &default_sched_class;
ffffffffc02050f6:	000b0717          	auipc	a4,0xb0
ffffffffc02050fa:	5cf73523          	sd	a5,1482(a4) # ffffffffc02b56c0 <sched_class>
{
ffffffffc02050fe:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205100:	000b0797          	auipc	a5,0xb0
ffffffffc0205104:	53078793          	addi	a5,a5,1328 # ffffffffc02b5630 <timer_list>
    rq = &__rq;
ffffffffc0205108:	000b0717          	auipc	a4,0xb0
ffffffffc020510c:	50870713          	addi	a4,a4,1288 # ffffffffc02b5610 <__rq>
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc0205110:	4615                	li	a2,5
ffffffffc0205112:	e79c                	sd	a5,8(a5)
ffffffffc0205114:	e39c                	sd	a5,0(a5)
    sched_class->init(rq);
ffffffffc0205116:	853a                	mv	a0,a4
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc0205118:	cb50                	sw	a2,20(a4)
    rq = &__rq;
ffffffffc020511a:	000b0797          	auipc	a5,0xb0
ffffffffc020511e:	58e7bf23          	sd	a4,1438(a5) # ffffffffc02b56b8 <rq>
    sched_class->init(rq);
ffffffffc0205122:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205124:	000b0797          	auipc	a5,0xb0
ffffffffc0205128:	59c7b783          	ld	a5,1436(a5) # ffffffffc02b56c0 <sched_class>
}
ffffffffc020512c:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020512e:	00002517          	auipc	a0,0x2
ffffffffc0205132:	33250513          	addi	a0,a0,818 # ffffffffc0207460 <etext+0x1bb8>
ffffffffc0205136:	638c                	ld	a1,0(a5)
}
ffffffffc0205138:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020513a:	85efb06f          	j	ffffffffc0200198 <cprintf>

ffffffffc020513e <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020513e:	4118                	lw	a4,0(a0)
{
ffffffffc0205140:	1101                	addi	sp,sp,-32
ffffffffc0205142:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205144:	478d                	li	a5,3
ffffffffc0205146:	0cf70863          	beq	a4,a5,ffffffffc0205216 <wakeup_proc+0xd8>
ffffffffc020514a:	85aa                	mv	a1,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020514c:	100027f3          	csrr	a5,sstatus
ffffffffc0205150:	8b89                	andi	a5,a5,2
ffffffffc0205152:	e3b1                	bnez	a5,ffffffffc0205196 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205154:	4789                	li	a5,2
ffffffffc0205156:	08f70563          	beq	a4,a5,ffffffffc02051e0 <wakeup_proc+0xa2>
        {
            proc->state = PROC_RUNNABLE;
            proc->wait_state = 0;
            if (proc != current)
ffffffffc020515a:	000b0717          	auipc	a4,0xb0
ffffffffc020515e:	54673703          	ld	a4,1350(a4) # ffffffffc02b56a0 <current>
            proc->wait_state = 0;
ffffffffc0205162:	0e052623          	sw	zero,236(a0)
            proc->state = PROC_RUNNABLE;
ffffffffc0205166:	c11c                	sw	a5,0(a0)
            if (proc != current)
ffffffffc0205168:	02e50463          	beq	a0,a4,ffffffffc0205190 <wakeup_proc+0x52>
    if (proc != idleproc)
ffffffffc020516c:	000b0797          	auipc	a5,0xb0
ffffffffc0205170:	5447b783          	ld	a5,1348(a5) # ffffffffc02b56b0 <idleproc>
ffffffffc0205174:	00f50e63          	beq	a0,a5,ffffffffc0205190 <wakeup_proc+0x52>
        sched_class->enqueue(rq, proc);
ffffffffc0205178:	000b0797          	auipc	a5,0xb0
ffffffffc020517c:	5487b783          	ld	a5,1352(a5) # ffffffffc02b56c0 <sched_class>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205180:	60e2                	ld	ra,24(sp)
        sched_class->enqueue(rq, proc);
ffffffffc0205182:	000b0517          	auipc	a0,0xb0
ffffffffc0205186:	53653503          	ld	a0,1334(a0) # ffffffffc02b56b8 <rq>
ffffffffc020518a:	6b9c                	ld	a5,16(a5)
}
ffffffffc020518c:	6105                	addi	sp,sp,32
        sched_class->enqueue(rq, proc);
ffffffffc020518e:	8782                	jr	a5
}
ffffffffc0205190:	60e2                	ld	ra,24(sp)
ffffffffc0205192:	6105                	addi	sp,sp,32
ffffffffc0205194:	8082                	ret
        intr_disable();
ffffffffc0205196:	e42a                	sd	a0,8(sp)
ffffffffc0205198:	f66fb0ef          	jal	ffffffffc02008fe <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020519c:	65a2                	ld	a1,8(sp)
ffffffffc020519e:	4789                	li	a5,2
ffffffffc02051a0:	4198                	lw	a4,0(a1)
ffffffffc02051a2:	04f70d63          	beq	a4,a5,ffffffffc02051fc <wakeup_proc+0xbe>
            if (proc != current)
ffffffffc02051a6:	000b0717          	auipc	a4,0xb0
ffffffffc02051aa:	4fa73703          	ld	a4,1274(a4) # ffffffffc02b56a0 <current>
            proc->wait_state = 0;
ffffffffc02051ae:	0e05a623          	sw	zero,236(a1)
            proc->state = PROC_RUNNABLE;
ffffffffc02051b2:	c19c                	sw	a5,0(a1)
            if (proc != current)
ffffffffc02051b4:	02e58263          	beq	a1,a4,ffffffffc02051d8 <wakeup_proc+0x9a>
    if (proc != idleproc)
ffffffffc02051b8:	000b0797          	auipc	a5,0xb0
ffffffffc02051bc:	4f87b783          	ld	a5,1272(a5) # ffffffffc02b56b0 <idleproc>
ffffffffc02051c0:	00f58c63          	beq	a1,a5,ffffffffc02051d8 <wakeup_proc+0x9a>
        sched_class->enqueue(rq, proc);
ffffffffc02051c4:	000b0797          	auipc	a5,0xb0
ffffffffc02051c8:	4fc7b783          	ld	a5,1276(a5) # ffffffffc02b56c0 <sched_class>
ffffffffc02051cc:	000b0517          	auipc	a0,0xb0
ffffffffc02051d0:	4ec53503          	ld	a0,1260(a0) # ffffffffc02b56b8 <rq>
ffffffffc02051d4:	6b9c                	ld	a5,16(a5)
ffffffffc02051d6:	9782                	jalr	a5
}
ffffffffc02051d8:	60e2                	ld	ra,24(sp)
ffffffffc02051da:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051dc:	f1cfb06f          	j	ffffffffc02008f8 <intr_enable>
ffffffffc02051e0:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc02051e2:	00002617          	auipc	a2,0x2
ffffffffc02051e6:	2ce60613          	addi	a2,a2,718 # ffffffffc02074b0 <etext+0x1c08>
ffffffffc02051ea:	05100593          	li	a1,81
ffffffffc02051ee:	00002517          	auipc	a0,0x2
ffffffffc02051f2:	2aa50513          	addi	a0,a0,682 # ffffffffc0207498 <etext+0x1bf0>
}
ffffffffc02051f6:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc02051f8:	abcfb06f          	j	ffffffffc02004b4 <__warn>
ffffffffc02051fc:	00002617          	auipc	a2,0x2
ffffffffc0205200:	2b460613          	addi	a2,a2,692 # ffffffffc02074b0 <etext+0x1c08>
ffffffffc0205204:	05100593          	li	a1,81
ffffffffc0205208:	00002517          	auipc	a0,0x2
ffffffffc020520c:	29050513          	addi	a0,a0,656 # ffffffffc0207498 <etext+0x1bf0>
ffffffffc0205210:	aa4fb0ef          	jal	ffffffffc02004b4 <__warn>
    if (flag)
ffffffffc0205214:	b7d1                	j	ffffffffc02051d8 <wakeup_proc+0x9a>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205216:	00002697          	auipc	a3,0x2
ffffffffc020521a:	26268693          	addi	a3,a3,610 # ffffffffc0207478 <etext+0x1bd0>
ffffffffc020521e:	00001617          	auipc	a2,0x1
ffffffffc0205222:	06a60613          	addi	a2,a2,106 # ffffffffc0206288 <etext+0x9e0>
ffffffffc0205226:	04200593          	li	a1,66
ffffffffc020522a:	00002517          	auipc	a0,0x2
ffffffffc020522e:	26e50513          	addi	a0,a0,622 # ffffffffc0207498 <etext+0x1bf0>
ffffffffc0205232:	a18fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0205236 <schedule>:

void schedule(void)
{
ffffffffc0205236:	7139                	addi	sp,sp,-64
ffffffffc0205238:	fc06                	sd	ra,56(sp)
ffffffffc020523a:	f822                	sd	s0,48(sp)
ffffffffc020523c:	f426                	sd	s1,40(sp)
ffffffffc020523e:	f04a                	sd	s2,32(sp)
ffffffffc0205240:	ec4e                	sd	s3,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205242:	100027f3          	csrr	a5,sstatus
ffffffffc0205246:	8b89                	andi	a5,a5,2
ffffffffc0205248:	4981                	li	s3,0
ffffffffc020524a:	efc9                	bnez	a5,ffffffffc02052e4 <schedule+0xae>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020524c:	000b0417          	auipc	s0,0xb0
ffffffffc0205250:	45440413          	addi	s0,s0,1108 # ffffffffc02b56a0 <current>
ffffffffc0205254:	600c                	ld	a1,0(s0)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205256:	4789                	li	a5,2
ffffffffc0205258:	000b0497          	auipc	s1,0xb0
ffffffffc020525c:	46048493          	addi	s1,s1,1120 # ffffffffc02b56b8 <rq>
ffffffffc0205260:	4198                	lw	a4,0(a1)
        current->need_resched = 0;
ffffffffc0205262:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205266:	000b0917          	auipc	s2,0xb0
ffffffffc020526a:	45a90913          	addi	s2,s2,1114 # ffffffffc02b56c0 <sched_class>
ffffffffc020526e:	04f70f63          	beq	a4,a5,ffffffffc02052cc <schedule+0x96>
    return sched_class->pick_next(rq);
ffffffffc0205272:	00093783          	ld	a5,0(s2)
ffffffffc0205276:	6088                	ld	a0,0(s1)
ffffffffc0205278:	739c                	ld	a5,32(a5)
ffffffffc020527a:	9782                	jalr	a5
ffffffffc020527c:	85aa                	mv	a1,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc020527e:	c131                	beqz	a0,ffffffffc02052c2 <schedule+0x8c>
    sched_class->dequeue(rq, proc);
ffffffffc0205280:	00093783          	ld	a5,0(s2)
ffffffffc0205284:	6088                	ld	a0,0(s1)
ffffffffc0205286:	e42e                	sd	a1,8(sp)
ffffffffc0205288:	6f9c                	ld	a5,24(a5)
ffffffffc020528a:	9782                	jalr	a5
ffffffffc020528c:	65a2                	ld	a1,8(sp)
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020528e:	459c                	lw	a5,8(a1)
        if (next != current)
ffffffffc0205290:	6018                	ld	a4,0(s0)
        next->runs++;
ffffffffc0205292:	2785                	addiw	a5,a5,1
ffffffffc0205294:	c59c                	sw	a5,8(a1)
        if (next != current)
ffffffffc0205296:	00b70563          	beq	a4,a1,ffffffffc02052a0 <schedule+0x6a>
        {
            proc_run(next);
ffffffffc020529a:	852e                	mv	a0,a1
ffffffffc020529c:	b3ffe0ef          	jal	ffffffffc0203dda <proc_run>
    if (flag)
ffffffffc02052a0:	00099963          	bnez	s3,ffffffffc02052b2 <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02052a4:	70e2                	ld	ra,56(sp)
ffffffffc02052a6:	7442                	ld	s0,48(sp)
ffffffffc02052a8:	74a2                	ld	s1,40(sp)
ffffffffc02052aa:	7902                	ld	s2,32(sp)
ffffffffc02052ac:	69e2                	ld	s3,24(sp)
ffffffffc02052ae:	6121                	addi	sp,sp,64
ffffffffc02052b0:	8082                	ret
ffffffffc02052b2:	7442                	ld	s0,48(sp)
ffffffffc02052b4:	70e2                	ld	ra,56(sp)
ffffffffc02052b6:	74a2                	ld	s1,40(sp)
ffffffffc02052b8:	7902                	ld	s2,32(sp)
ffffffffc02052ba:	69e2                	ld	s3,24(sp)
ffffffffc02052bc:	6121                	addi	sp,sp,64
        intr_enable();
ffffffffc02052be:	e3afb06f          	j	ffffffffc02008f8 <intr_enable>
            next = idleproc;
ffffffffc02052c2:	000b0597          	auipc	a1,0xb0
ffffffffc02052c6:	3ee5b583          	ld	a1,1006(a1) # ffffffffc02b56b0 <idleproc>
ffffffffc02052ca:	b7d1                	j	ffffffffc020528e <schedule+0x58>
    if (proc != idleproc)
ffffffffc02052cc:	000b0797          	auipc	a5,0xb0
ffffffffc02052d0:	3e47b783          	ld	a5,996(a5) # ffffffffc02b56b0 <idleproc>
ffffffffc02052d4:	f8f58fe3          	beq	a1,a5,ffffffffc0205272 <schedule+0x3c>
        sched_class->enqueue(rq, proc);
ffffffffc02052d8:	00093783          	ld	a5,0(s2)
ffffffffc02052dc:	6088                	ld	a0,0(s1)
ffffffffc02052de:	6b9c                	ld	a5,16(a5)
ffffffffc02052e0:	9782                	jalr	a5
ffffffffc02052e2:	bf41                	j	ffffffffc0205272 <schedule+0x3c>
        intr_disable();
ffffffffc02052e4:	e1afb0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc02052e8:	4985                	li	s3,1
ffffffffc02052ea:	b78d                	j	ffffffffc020524c <schedule+0x16>

ffffffffc02052ec <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052ec:	000b0797          	auipc	a5,0xb0
ffffffffc02052f0:	3b47b783          	ld	a5,948(a5) # ffffffffc02b56a0 <current>
}
ffffffffc02052f4:	43c8                	lw	a0,4(a5)
ffffffffc02052f6:	8082                	ret

ffffffffc02052f8 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052f8:	4501                	li	a0,0
ffffffffc02052fa:	8082                	ret

ffffffffc02052fc <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc02052fc:	000b0797          	auipc	a5,0xb0
ffffffffc0205300:	34c7b783          	ld	a5,844(a5) # ffffffffc02b5648 <ticks>
ffffffffc0205304:	0027951b          	slliw	a0,a5,0x2
ffffffffc0205308:	9d3d                	addw	a0,a0,a5
ffffffffc020530a:	0015151b          	slliw	a0,a0,0x1
}
ffffffffc020530e:	8082                	ret

ffffffffc0205310 <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc0205310:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc0205312:	1141                	addi	sp,sp,-16
ffffffffc0205314:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc0205316:	c7dff0ef          	jal	ffffffffc0204f92 <lab6_set_priority>
    return 0;
}
ffffffffc020531a:	60a2                	ld	ra,8(sp)
ffffffffc020531c:	4501                	li	a0,0
ffffffffc020531e:	0141                	addi	sp,sp,16
ffffffffc0205320:	8082                	ret

ffffffffc0205322 <sys_putc>:
    cputchar(c);
ffffffffc0205322:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205324:	1141                	addi	sp,sp,-16
ffffffffc0205326:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205328:	ea5fa0ef          	jal	ffffffffc02001cc <cputchar>
}
ffffffffc020532c:	60a2                	ld	ra,8(sp)
ffffffffc020532e:	4501                	li	a0,0
ffffffffc0205330:	0141                	addi	sp,sp,16
ffffffffc0205332:	8082                	ret

ffffffffc0205334 <sys_kill>:
    return do_kill(pid);
ffffffffc0205334:	4108                	lw	a0,0(a0)
ffffffffc0205336:	a2bff06f          	j	ffffffffc0204d60 <do_kill>

ffffffffc020533a <sys_yield>:
    return do_yield();
ffffffffc020533a:	9ddff06f          	j	ffffffffc0204d16 <do_yield>

ffffffffc020533e <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020533e:	6d14                	ld	a3,24(a0)
ffffffffc0205340:	6910                	ld	a2,16(a0)
ffffffffc0205342:	650c                	ld	a1,8(a0)
ffffffffc0205344:	6108                	ld	a0,0(a0)
ffffffffc0205346:	ba4ff06f          	j	ffffffffc02046ea <do_execve>

ffffffffc020534a <sys_wait>:
    return do_wait(pid, store);
ffffffffc020534a:	650c                	ld	a1,8(a0)
ffffffffc020534c:	4108                	lw	a0,0(a0)
ffffffffc020534e:	9d9ff06f          	j	ffffffffc0204d26 <do_wait>

ffffffffc0205352 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205352:	000b0797          	auipc	a5,0xb0
ffffffffc0205356:	34e7b783          	ld	a5,846(a5) # ffffffffc02b56a0 <current>
    return do_fork(0, stack, tf);
ffffffffc020535a:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc020535c:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020535e:	6a0c                	ld	a1,16(a2)
ffffffffc0205360:	aedfe06f          	j	ffffffffc0203e4c <do_fork>

ffffffffc0205364 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205364:	4108                	lw	a0,0(a0)
ffffffffc0205366:	f3bfe06f          	j	ffffffffc02042a0 <do_exit>

ffffffffc020536a <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc020536a:	000b0697          	auipc	a3,0xb0
ffffffffc020536e:	3366b683          	ld	a3,822(a3) # ffffffffc02b56a0 <current>
syscall(void) {
ffffffffc0205372:	715d                	addi	sp,sp,-80
ffffffffc0205374:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205376:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc0205378:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020537a:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc020537e:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205380:	02d7ec63          	bltu	a5,a3,ffffffffc02053b8 <syscall+0x4e>
        if (syscalls[num] != NULL) {
ffffffffc0205384:	00002797          	auipc	a5,0x2
ffffffffc0205388:	37478793          	addi	a5,a5,884 # ffffffffc02076f8 <syscalls>
ffffffffc020538c:	00369613          	slli	a2,a3,0x3
ffffffffc0205390:	97b2                	add	a5,a5,a2
ffffffffc0205392:	639c                	ld	a5,0(a5)
ffffffffc0205394:	c395                	beqz	a5,ffffffffc02053b8 <syscall+0x4e>
            arg[0] = tf->gpr.a1;
ffffffffc0205396:	7028                	ld	a0,96(s0)
ffffffffc0205398:	742c                	ld	a1,104(s0)
ffffffffc020539a:	7830                	ld	a2,112(s0)
ffffffffc020539c:	7c34                	ld	a3,120(s0)
ffffffffc020539e:	6c38                	ld	a4,88(s0)
ffffffffc02053a0:	f02a                	sd	a0,32(sp)
ffffffffc02053a2:	f42e                	sd	a1,40(sp)
ffffffffc02053a4:	f832                	sd	a2,48(sp)
ffffffffc02053a6:	fc36                	sd	a3,56(sp)
ffffffffc02053a8:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053aa:	0828                	addi	a0,sp,24
ffffffffc02053ac:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02053ae:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053b0:	e828                	sd	a0,80(s0)
}
ffffffffc02053b2:	6406                	ld	s0,64(sp)
ffffffffc02053b4:	6161                	addi	sp,sp,80
ffffffffc02053b6:	8082                	ret
    print_trapframe(tf);
ffffffffc02053b8:	8522                	mv	a0,s0
ffffffffc02053ba:	e436                	sd	a3,8(sp)
ffffffffc02053bc:	f32fb0ef          	jal	ffffffffc0200aee <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02053c0:	000b0797          	auipc	a5,0xb0
ffffffffc02053c4:	2e07b783          	ld	a5,736(a5) # ffffffffc02b56a0 <current>
ffffffffc02053c8:	66a2                	ld	a3,8(sp)
ffffffffc02053ca:	00002617          	auipc	a2,0x2
ffffffffc02053ce:	10660613          	addi	a2,a2,262 # ffffffffc02074d0 <etext+0x1c28>
ffffffffc02053d2:	43d8                	lw	a4,4(a5)
ffffffffc02053d4:	06c00593          	li	a1,108
ffffffffc02053d8:	0b478793          	addi	a5,a5,180
ffffffffc02053dc:	00002517          	auipc	a0,0x2
ffffffffc02053e0:	12450513          	addi	a0,a0,292 # ffffffffc0207500 <etext+0x1c58>
ffffffffc02053e4:	866fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02053e8 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02053e8:	9e3707b7          	lui	a5,0x9e370
ffffffffc02053ec:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_matrix_out_size+0xffffffff9e364ac1>
ffffffffc02053ee:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc02053f2:	02000513          	li	a0,32
ffffffffc02053f6:	9d0d                	subw	a0,a0,a1
}
ffffffffc02053f8:	00a7d53b          	srlw	a0,a5,a0
ffffffffc02053fc:	8082                	ret

ffffffffc02053fe <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053fe:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205400:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205404:	f022                	sd	s0,32(sp)
ffffffffc0205406:	ec26                	sd	s1,24(sp)
ffffffffc0205408:	e84a                	sd	s2,16(sp)
ffffffffc020540a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020540c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205410:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205412:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205416:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020541a:	84aa                	mv	s1,a0
ffffffffc020541c:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc020541e:	03067d63          	bgeu	a2,a6,ffffffffc0205458 <printnum+0x5a>
ffffffffc0205422:	e44e                	sd	s3,8(sp)
ffffffffc0205424:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205426:	4785                	li	a5,1
ffffffffc0205428:	00e7d763          	bge	a5,a4,ffffffffc0205436 <printnum+0x38>
            putch(padc, putdat);
ffffffffc020542c:	85ca                	mv	a1,s2
ffffffffc020542e:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0205430:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205432:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205434:	fc65                	bnez	s0,ffffffffc020542c <printnum+0x2e>
ffffffffc0205436:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205438:	00002797          	auipc	a5,0x2
ffffffffc020543c:	0e078793          	addi	a5,a5,224 # ffffffffc0207518 <etext+0x1c70>
ffffffffc0205440:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205442:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205444:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0205448:	70a2                	ld	ra,40(sp)
ffffffffc020544a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020544c:	85ca                	mv	a1,s2
ffffffffc020544e:	87a6                	mv	a5,s1
}
ffffffffc0205450:	6942                	ld	s2,16(sp)
ffffffffc0205452:	64e2                	ld	s1,24(sp)
ffffffffc0205454:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205456:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205458:	03065633          	divu	a2,a2,a6
ffffffffc020545c:	8722                	mv	a4,s0
ffffffffc020545e:	fa1ff0ef          	jal	ffffffffc02053fe <printnum>
ffffffffc0205462:	bfd9                	j	ffffffffc0205438 <printnum+0x3a>

ffffffffc0205464 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205464:	7119                	addi	sp,sp,-128
ffffffffc0205466:	f4a6                	sd	s1,104(sp)
ffffffffc0205468:	f0ca                	sd	s2,96(sp)
ffffffffc020546a:	ecce                	sd	s3,88(sp)
ffffffffc020546c:	e8d2                	sd	s4,80(sp)
ffffffffc020546e:	e4d6                	sd	s5,72(sp)
ffffffffc0205470:	e0da                	sd	s6,64(sp)
ffffffffc0205472:	f862                	sd	s8,48(sp)
ffffffffc0205474:	fc86                	sd	ra,120(sp)
ffffffffc0205476:	f8a2                	sd	s0,112(sp)
ffffffffc0205478:	fc5e                	sd	s7,56(sp)
ffffffffc020547a:	f466                	sd	s9,40(sp)
ffffffffc020547c:	f06a                	sd	s10,32(sp)
ffffffffc020547e:	ec6e                	sd	s11,24(sp)
ffffffffc0205480:	84aa                	mv	s1,a0
ffffffffc0205482:	8c32                	mv	s8,a2
ffffffffc0205484:	8a36                	mv	s4,a3
ffffffffc0205486:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205488:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020548c:	05500b13          	li	s6,85
ffffffffc0205490:	00003a97          	auipc	s5,0x3
ffffffffc0205494:	a68a8a93          	addi	s5,s5,-1432 # ffffffffc0207ef8 <syscalls+0x800>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205498:	000c4503          	lbu	a0,0(s8)
ffffffffc020549c:	001c0413          	addi	s0,s8,1
ffffffffc02054a0:	01350a63          	beq	a0,s3,ffffffffc02054b4 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02054a4:	cd0d                	beqz	a0,ffffffffc02054de <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02054a6:	85ca                	mv	a1,s2
ffffffffc02054a8:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054aa:	00044503          	lbu	a0,0(s0)
ffffffffc02054ae:	0405                	addi	s0,s0,1
ffffffffc02054b0:	ff351ae3          	bne	a0,s3,ffffffffc02054a4 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc02054b4:	5cfd                	li	s9,-1
ffffffffc02054b6:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc02054b8:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02054bc:	4b81                	li	s7,0
ffffffffc02054be:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054c0:	00044683          	lbu	a3,0(s0)
ffffffffc02054c4:	00140c13          	addi	s8,s0,1
ffffffffc02054c8:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02054cc:	0ff5f593          	zext.b	a1,a1
ffffffffc02054d0:	02bb6663          	bltu	s6,a1,ffffffffc02054fc <vprintfmt+0x98>
ffffffffc02054d4:	058a                	slli	a1,a1,0x2
ffffffffc02054d6:	95d6                	add	a1,a1,s5
ffffffffc02054d8:	4198                	lw	a4,0(a1)
ffffffffc02054da:	9756                	add	a4,a4,s5
ffffffffc02054dc:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02054de:	70e6                	ld	ra,120(sp)
ffffffffc02054e0:	7446                	ld	s0,112(sp)
ffffffffc02054e2:	74a6                	ld	s1,104(sp)
ffffffffc02054e4:	7906                	ld	s2,96(sp)
ffffffffc02054e6:	69e6                	ld	s3,88(sp)
ffffffffc02054e8:	6a46                	ld	s4,80(sp)
ffffffffc02054ea:	6aa6                	ld	s5,72(sp)
ffffffffc02054ec:	6b06                	ld	s6,64(sp)
ffffffffc02054ee:	7be2                	ld	s7,56(sp)
ffffffffc02054f0:	7c42                	ld	s8,48(sp)
ffffffffc02054f2:	7ca2                	ld	s9,40(sp)
ffffffffc02054f4:	7d02                	ld	s10,32(sp)
ffffffffc02054f6:	6de2                	ld	s11,24(sp)
ffffffffc02054f8:	6109                	addi	sp,sp,128
ffffffffc02054fa:	8082                	ret
            putch('%', putdat);
ffffffffc02054fc:	85ca                	mv	a1,s2
ffffffffc02054fe:	02500513          	li	a0,37
ffffffffc0205502:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205504:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205508:	02500713          	li	a4,37
ffffffffc020550c:	8c22                	mv	s8,s0
ffffffffc020550e:	f8e785e3          	beq	a5,a4,ffffffffc0205498 <vprintfmt+0x34>
ffffffffc0205512:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0205516:	1c7d                	addi	s8,s8,-1
ffffffffc0205518:	fee79de3          	bne	a5,a4,ffffffffc0205512 <vprintfmt+0xae>
ffffffffc020551c:	bfb5                	j	ffffffffc0205498 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020551e:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0205522:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0205524:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0205528:	fd06071b          	addiw	a4,a2,-48
ffffffffc020552c:	24e56a63          	bltu	a0,a4,ffffffffc0205780 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0205530:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205532:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0205534:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0205538:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020553c:	0197073b          	addw	a4,a4,s9
ffffffffc0205540:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205544:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205546:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020554a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020554c:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0205550:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0205554:	feb570e3          	bgeu	a0,a1,ffffffffc0205534 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0205558:	f60d54e3          	bgez	s10,ffffffffc02054c0 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc020555c:	8d66                	mv	s10,s9
ffffffffc020555e:	5cfd                	li	s9,-1
ffffffffc0205560:	b785                	j	ffffffffc02054c0 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205562:	8db6                	mv	s11,a3
ffffffffc0205564:	8462                	mv	s0,s8
ffffffffc0205566:	bfa9                	j	ffffffffc02054c0 <vprintfmt+0x5c>
ffffffffc0205568:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc020556a:	4b85                	li	s7,1
            goto reswitch;
ffffffffc020556c:	bf91                	j	ffffffffc02054c0 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc020556e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205570:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205574:	00f74463          	blt	a4,a5,ffffffffc020557c <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205578:	1a078763          	beqz	a5,ffffffffc0205726 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc020557c:	000a3603          	ld	a2,0(s4)
ffffffffc0205580:	46c1                	li	a3,16
ffffffffc0205582:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205584:	000d879b          	sext.w	a5,s11
ffffffffc0205588:	876a                	mv	a4,s10
ffffffffc020558a:	85ca                	mv	a1,s2
ffffffffc020558c:	8526                	mv	a0,s1
ffffffffc020558e:	e71ff0ef          	jal	ffffffffc02053fe <printnum>
            break;
ffffffffc0205592:	b719                	j	ffffffffc0205498 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0205594:	000a2503          	lw	a0,0(s4)
ffffffffc0205598:	85ca                	mv	a1,s2
ffffffffc020559a:	0a21                	addi	s4,s4,8
ffffffffc020559c:	9482                	jalr	s1
            break;
ffffffffc020559e:	bded                	j	ffffffffc0205498 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02055a0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055a2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055a6:	00f74463          	blt	a4,a5,ffffffffc02055ae <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02055aa:	16078963          	beqz	a5,ffffffffc020571c <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc02055ae:	000a3603          	ld	a2,0(s4)
ffffffffc02055b2:	46a9                	li	a3,10
ffffffffc02055b4:	8a2e                	mv	s4,a1
ffffffffc02055b6:	b7f9                	j	ffffffffc0205584 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc02055b8:	85ca                	mv	a1,s2
ffffffffc02055ba:	03000513          	li	a0,48
ffffffffc02055be:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc02055c0:	85ca                	mv	a1,s2
ffffffffc02055c2:	07800513          	li	a0,120
ffffffffc02055c6:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055c8:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02055cc:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055ce:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055d0:	bf55                	j	ffffffffc0205584 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02055d2:	85ca                	mv	a1,s2
ffffffffc02055d4:	02500513          	li	a0,37
ffffffffc02055d8:	9482                	jalr	s1
            break;
ffffffffc02055da:	bd7d                	j	ffffffffc0205498 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02055dc:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055e0:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02055e2:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02055e4:	bf95                	j	ffffffffc0205558 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc02055e6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055e8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055ec:	00f74463          	blt	a4,a5,ffffffffc02055f4 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc02055f0:	12078163          	beqz	a5,ffffffffc0205712 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc02055f4:	000a3603          	ld	a2,0(s4)
ffffffffc02055f8:	46a1                	li	a3,8
ffffffffc02055fa:	8a2e                	mv	s4,a1
ffffffffc02055fc:	b761                	j	ffffffffc0205584 <vprintfmt+0x120>
            if (width < 0)
ffffffffc02055fe:	876a                	mv	a4,s10
ffffffffc0205600:	000d5363          	bgez	s10,ffffffffc0205606 <vprintfmt+0x1a2>
ffffffffc0205604:	4701                	li	a4,0
ffffffffc0205606:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020560a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020560c:	bd55                	j	ffffffffc02054c0 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020560e:	000d841b          	sext.w	s0,s11
ffffffffc0205612:	fd340793          	addi	a5,s0,-45
ffffffffc0205616:	00f037b3          	snez	a5,a5
ffffffffc020561a:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020561e:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0205622:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205624:	008a0793          	addi	a5,s4,8
ffffffffc0205628:	e43e                	sd	a5,8(sp)
ffffffffc020562a:	100d8c63          	beqz	s11,ffffffffc0205742 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc020562e:	12071363          	bnez	a4,ffffffffc0205754 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205632:	000dc783          	lbu	a5,0(s11)
ffffffffc0205636:	0007851b          	sext.w	a0,a5
ffffffffc020563a:	c78d                	beqz	a5,ffffffffc0205664 <vprintfmt+0x200>
ffffffffc020563c:	0d85                	addi	s11,s11,1
ffffffffc020563e:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205640:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205644:	000cc563          	bltz	s9,ffffffffc020564e <vprintfmt+0x1ea>
ffffffffc0205648:	3cfd                	addiw	s9,s9,-1
ffffffffc020564a:	008c8d63          	beq	s9,s0,ffffffffc0205664 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020564e:	020b9663          	bnez	s7,ffffffffc020567a <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0205652:	85ca                	mv	a1,s2
ffffffffc0205654:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205656:	000dc783          	lbu	a5,0(s11)
ffffffffc020565a:	0d85                	addi	s11,s11,1
ffffffffc020565c:	3d7d                	addiw	s10,s10,-1
ffffffffc020565e:	0007851b          	sext.w	a0,a5
ffffffffc0205662:	f3ed                	bnez	a5,ffffffffc0205644 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0205664:	01a05963          	blez	s10,ffffffffc0205676 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0205668:	85ca                	mv	a1,s2
ffffffffc020566a:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020566e:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0205670:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0205672:	fe0d1be3          	bnez	s10,ffffffffc0205668 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205676:	6a22                	ld	s4,8(sp)
ffffffffc0205678:	b505                	j	ffffffffc0205498 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020567a:	3781                	addiw	a5,a5,-32
ffffffffc020567c:	fcfa7be3          	bgeu	s4,a5,ffffffffc0205652 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0205680:	03f00513          	li	a0,63
ffffffffc0205684:	85ca                	mv	a1,s2
ffffffffc0205686:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205688:	000dc783          	lbu	a5,0(s11)
ffffffffc020568c:	0d85                	addi	s11,s11,1
ffffffffc020568e:	3d7d                	addiw	s10,s10,-1
ffffffffc0205690:	0007851b          	sext.w	a0,a5
ffffffffc0205694:	dbe1                	beqz	a5,ffffffffc0205664 <vprintfmt+0x200>
ffffffffc0205696:	fa0cd9e3          	bgez	s9,ffffffffc0205648 <vprintfmt+0x1e4>
ffffffffc020569a:	b7c5                	j	ffffffffc020567a <vprintfmt+0x216>
            if (err < 0) {
ffffffffc020569c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056a0:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc02056a2:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02056a4:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02056a8:	8fb9                	xor	a5,a5,a4
ffffffffc02056aa:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056ae:	02d64563          	blt	a2,a3,ffffffffc02056d8 <vprintfmt+0x274>
ffffffffc02056b2:	00003797          	auipc	a5,0x3
ffffffffc02056b6:	99e78793          	addi	a5,a5,-1634 # ffffffffc0208050 <error_string>
ffffffffc02056ba:	00369713          	slli	a4,a3,0x3
ffffffffc02056be:	97ba                	add	a5,a5,a4
ffffffffc02056c0:	639c                	ld	a5,0(a5)
ffffffffc02056c2:	cb99                	beqz	a5,ffffffffc02056d8 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc02056c4:	86be                	mv	a3,a5
ffffffffc02056c6:	00000617          	auipc	a2,0x0
ffffffffc02056ca:	20a60613          	addi	a2,a2,522 # ffffffffc02058d0 <etext+0x28>
ffffffffc02056ce:	85ca                	mv	a1,s2
ffffffffc02056d0:	8526                	mv	a0,s1
ffffffffc02056d2:	0d8000ef          	jal	ffffffffc02057aa <printfmt>
ffffffffc02056d6:	b3c9                	j	ffffffffc0205498 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056d8:	00002617          	auipc	a2,0x2
ffffffffc02056dc:	e6060613          	addi	a2,a2,-416 # ffffffffc0207538 <etext+0x1c90>
ffffffffc02056e0:	85ca                	mv	a1,s2
ffffffffc02056e2:	8526                	mv	a0,s1
ffffffffc02056e4:	0c6000ef          	jal	ffffffffc02057aa <printfmt>
ffffffffc02056e8:	bb45                	j	ffffffffc0205498 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02056ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056ec:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02056f0:	00f74363          	blt	a4,a5,ffffffffc02056f6 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc02056f4:	cf81                	beqz	a5,ffffffffc020570c <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc02056f6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02056fa:	02044b63          	bltz	s0,ffffffffc0205730 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02056fe:	8622                	mv	a2,s0
ffffffffc0205700:	8a5e                	mv	s4,s7
ffffffffc0205702:	46a9                	li	a3,10
ffffffffc0205704:	b541                	j	ffffffffc0205584 <vprintfmt+0x120>
            lflag ++;
ffffffffc0205706:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205708:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020570a:	bb5d                	j	ffffffffc02054c0 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc020570c:	000a2403          	lw	s0,0(s4)
ffffffffc0205710:	b7ed                	j	ffffffffc02056fa <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0205712:	000a6603          	lwu	a2,0(s4)
ffffffffc0205716:	46a1                	li	a3,8
ffffffffc0205718:	8a2e                	mv	s4,a1
ffffffffc020571a:	b5ad                	j	ffffffffc0205584 <vprintfmt+0x120>
ffffffffc020571c:	000a6603          	lwu	a2,0(s4)
ffffffffc0205720:	46a9                	li	a3,10
ffffffffc0205722:	8a2e                	mv	s4,a1
ffffffffc0205724:	b585                	j	ffffffffc0205584 <vprintfmt+0x120>
ffffffffc0205726:	000a6603          	lwu	a2,0(s4)
ffffffffc020572a:	46c1                	li	a3,16
ffffffffc020572c:	8a2e                	mv	s4,a1
ffffffffc020572e:	bd99                	j	ffffffffc0205584 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0205730:	85ca                	mv	a1,s2
ffffffffc0205732:	02d00513          	li	a0,45
ffffffffc0205736:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0205738:	40800633          	neg	a2,s0
ffffffffc020573c:	8a5e                	mv	s4,s7
ffffffffc020573e:	46a9                	li	a3,10
ffffffffc0205740:	b591                	j	ffffffffc0205584 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0205742:	e329                	bnez	a4,ffffffffc0205784 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205744:	02800793          	li	a5,40
ffffffffc0205748:	853e                	mv	a0,a5
ffffffffc020574a:	00002d97          	auipc	s11,0x2
ffffffffc020574e:	de7d8d93          	addi	s11,s11,-537 # ffffffffc0207531 <etext+0x1c89>
ffffffffc0205752:	b5f5                	j	ffffffffc020563e <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205754:	85e6                	mv	a1,s9
ffffffffc0205756:	856e                	mv	a0,s11
ffffffffc0205758:	08a000ef          	jal	ffffffffc02057e2 <strnlen>
ffffffffc020575c:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0205760:	01a05863          	blez	s10,ffffffffc0205770 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0205764:	85ca                	mv	a1,s2
ffffffffc0205766:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205768:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc020576a:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020576c:	fe0d1ce3          	bnez	s10,ffffffffc0205764 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205770:	000dc783          	lbu	a5,0(s11)
ffffffffc0205774:	0007851b          	sext.w	a0,a5
ffffffffc0205778:	ec0792e3          	bnez	a5,ffffffffc020563c <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020577c:	6a22                	ld	s4,8(sp)
ffffffffc020577e:	bb29                	j	ffffffffc0205498 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205780:	8462                	mv	s0,s8
ffffffffc0205782:	bbd9                	j	ffffffffc0205558 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205784:	85e6                	mv	a1,s9
ffffffffc0205786:	00002517          	auipc	a0,0x2
ffffffffc020578a:	daa50513          	addi	a0,a0,-598 # ffffffffc0207530 <etext+0x1c88>
ffffffffc020578e:	054000ef          	jal	ffffffffc02057e2 <strnlen>
ffffffffc0205792:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205796:	02800793          	li	a5,40
                p = "(null)";
ffffffffc020579a:	00002d97          	auipc	s11,0x2
ffffffffc020579e:	d96d8d93          	addi	s11,s11,-618 # ffffffffc0207530 <etext+0x1c88>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057a2:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02057a4:	fda040e3          	bgtz	s10,ffffffffc0205764 <vprintfmt+0x300>
ffffffffc02057a8:	bd51                	j	ffffffffc020563c <vprintfmt+0x1d8>

ffffffffc02057aa <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057aa:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02057ac:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057b0:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057b2:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057b4:	ec06                	sd	ra,24(sp)
ffffffffc02057b6:	f83a                	sd	a4,48(sp)
ffffffffc02057b8:	fc3e                	sd	a5,56(sp)
ffffffffc02057ba:	e0c2                	sd	a6,64(sp)
ffffffffc02057bc:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02057be:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057c0:	ca5ff0ef          	jal	ffffffffc0205464 <vprintfmt>
}
ffffffffc02057c4:	60e2                	ld	ra,24(sp)
ffffffffc02057c6:	6161                	addi	sp,sp,80
ffffffffc02057c8:	8082                	ret

ffffffffc02057ca <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02057ca:	00054783          	lbu	a5,0(a0)
ffffffffc02057ce:	cb81                	beqz	a5,ffffffffc02057de <strlen+0x14>
    size_t cnt = 0;
ffffffffc02057d0:	4781                	li	a5,0
        cnt ++;
ffffffffc02057d2:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02057d4:	00f50733          	add	a4,a0,a5
ffffffffc02057d8:	00074703          	lbu	a4,0(a4)
ffffffffc02057dc:	fb7d                	bnez	a4,ffffffffc02057d2 <strlen+0x8>
    }
    return cnt;
}
ffffffffc02057de:	853e                	mv	a0,a5
ffffffffc02057e0:	8082                	ret

ffffffffc02057e2 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02057e2:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057e4:	e589                	bnez	a1,ffffffffc02057ee <strnlen+0xc>
ffffffffc02057e6:	a811                	j	ffffffffc02057fa <strnlen+0x18>
        cnt ++;
ffffffffc02057e8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057ea:	00f58863          	beq	a1,a5,ffffffffc02057fa <strnlen+0x18>
ffffffffc02057ee:	00f50733          	add	a4,a0,a5
ffffffffc02057f2:	00074703          	lbu	a4,0(a4)
ffffffffc02057f6:	fb6d                	bnez	a4,ffffffffc02057e8 <strnlen+0x6>
ffffffffc02057f8:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02057fa:	852e                	mv	a0,a1
ffffffffc02057fc:	8082                	ret

ffffffffc02057fe <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02057fe:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205800:	0005c703          	lbu	a4,0(a1)
ffffffffc0205804:	0585                	addi	a1,a1,1
ffffffffc0205806:	0785                	addi	a5,a5,1
ffffffffc0205808:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020580c:	fb75                	bnez	a4,ffffffffc0205800 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020580e:	8082                	ret

ffffffffc0205810 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205810:	00054783          	lbu	a5,0(a0)
ffffffffc0205814:	e791                	bnez	a5,ffffffffc0205820 <strcmp+0x10>
ffffffffc0205816:	a01d                	j	ffffffffc020583c <strcmp+0x2c>
ffffffffc0205818:	00054783          	lbu	a5,0(a0)
ffffffffc020581c:	cb99                	beqz	a5,ffffffffc0205832 <strcmp+0x22>
ffffffffc020581e:	0585                	addi	a1,a1,1
ffffffffc0205820:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0205824:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205826:	fef709e3          	beq	a4,a5,ffffffffc0205818 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020582a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020582e:	9d19                	subw	a0,a0,a4
ffffffffc0205830:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205832:	0015c703          	lbu	a4,1(a1)
ffffffffc0205836:	4501                	li	a0,0
}
ffffffffc0205838:	9d19                	subw	a0,a0,a4
ffffffffc020583a:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020583c:	0005c703          	lbu	a4,0(a1)
ffffffffc0205840:	4501                	li	a0,0
ffffffffc0205842:	b7f5                	j	ffffffffc020582e <strcmp+0x1e>

ffffffffc0205844 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205844:	ce01                	beqz	a2,ffffffffc020585c <strncmp+0x18>
ffffffffc0205846:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020584a:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020584c:	cb91                	beqz	a5,ffffffffc0205860 <strncmp+0x1c>
ffffffffc020584e:	0005c703          	lbu	a4,0(a1)
ffffffffc0205852:	00f71763          	bne	a4,a5,ffffffffc0205860 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0205856:	0505                	addi	a0,a0,1
ffffffffc0205858:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020585a:	f675                	bnez	a2,ffffffffc0205846 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020585c:	4501                	li	a0,0
ffffffffc020585e:	8082                	ret
ffffffffc0205860:	00054503          	lbu	a0,0(a0)
ffffffffc0205864:	0005c783          	lbu	a5,0(a1)
ffffffffc0205868:	9d1d                	subw	a0,a0,a5
}
ffffffffc020586a:	8082                	ret

ffffffffc020586c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020586c:	a021                	j	ffffffffc0205874 <strchr+0x8>
        if (*s == c) {
ffffffffc020586e:	00f58763          	beq	a1,a5,ffffffffc020587c <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0205872:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205874:	00054783          	lbu	a5,0(a0)
ffffffffc0205878:	fbfd                	bnez	a5,ffffffffc020586e <strchr+0x2>
    }
    return NULL;
ffffffffc020587a:	4501                	li	a0,0
}
ffffffffc020587c:	8082                	ret

ffffffffc020587e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020587e:	ca01                	beqz	a2,ffffffffc020588e <memset+0x10>
ffffffffc0205880:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205882:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205884:	0785                	addi	a5,a5,1
ffffffffc0205886:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020588a:	fef61de3          	bne	a2,a5,ffffffffc0205884 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020588e:	8082                	ret

ffffffffc0205890 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205890:	ca19                	beqz	a2,ffffffffc02058a6 <memcpy+0x16>
ffffffffc0205892:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205894:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205896:	0005c703          	lbu	a4,0(a1)
ffffffffc020589a:	0585                	addi	a1,a1,1
ffffffffc020589c:	0785                	addi	a5,a5,1
ffffffffc020589e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02058a2:	feb61ae3          	bne	a2,a1,ffffffffc0205896 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02058a6:	8082                	ret
