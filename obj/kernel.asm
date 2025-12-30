
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
ffffffffc0200062:	019050ef          	jal	ffffffffc020587a <memset>
    cons_init(); // init the console
ffffffffc0200066:	4da000ef          	jal	ffffffffc0200540 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	83e58593          	addi	a1,a1,-1986 # ffffffffc02058a8 <etext+0x4>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	85650513          	addi	a0,a0,-1962 # ffffffffc02058c8 <etext+0x24>
ffffffffc020007a:	11e000ef          	jal	ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1ac000ef          	jal	ffffffffc020022a <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	530000ef          	jal	ffffffffc02005b2 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	7ce020ef          	jal	ffffffffc0202854 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	07b000ef          	jal	ffffffffc0200904 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	079000ef          	jal	ffffffffc0200906 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	059030ef          	jal	ffffffffc02038ea <vmm_init>
    sched_init();
ffffffffc0200096:	050050ef          	jal	ffffffffc02050e6 <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	53b040ef          	jal	ffffffffc0204dd4 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	45a000ef          	jal	ffffffffc02004f8 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	057000ef          	jal	ffffffffc02008f8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	6cf040ef          	jal	ffffffffc0204f74 <cpu_idle>

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
ffffffffc02000be:	81650513          	addi	a0,a0,-2026 # ffffffffc02058d0 <etext+0x2c>
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
ffffffffc020018c:	2d4050ef          	jal	ffffffffc0205460 <vprintfmt>
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
ffffffffc02001c0:	2a0050ef          	jal	ffffffffc0205460 <vprintfmt>
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
ffffffffc0200230:	6ac50513          	addi	a0,a0,1708 # ffffffffc02058d8 <etext+0x34>
void print_kerninfo(void) {
ffffffffc0200234:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200236:	f63ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020023a:	00000597          	auipc	a1,0x0
ffffffffc020023e:	e1058593          	addi	a1,a1,-496 # ffffffffc020004a <kern_init>
ffffffffc0200242:	00005517          	auipc	a0,0x5
ffffffffc0200246:	6b650513          	addi	a0,a0,1718 # ffffffffc02058f8 <etext+0x54>
ffffffffc020024a:	f4fff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024e:	00005597          	auipc	a1,0x5
ffffffffc0200252:	65658593          	addi	a1,a1,1622 # ffffffffc02058a4 <etext>
ffffffffc0200256:	00005517          	auipc	a0,0x5
ffffffffc020025a:	6c250513          	addi	a0,a0,1730 # ffffffffc0205918 <etext+0x74>
ffffffffc020025e:	f3bff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200262:	000b1597          	auipc	a1,0xb1
ffffffffc0200266:	f8658593          	addi	a1,a1,-122 # ffffffffc02b11e8 <buf>
ffffffffc020026a:	00005517          	auipc	a0,0x5
ffffffffc020026e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0205938 <etext+0x94>
ffffffffc0200272:	f27ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200276:	000b5597          	auipc	a1,0xb5
ffffffffc020027a:	45258593          	addi	a1,a1,1106 # ffffffffc02b56c8 <end>
ffffffffc020027e:	00005517          	auipc	a0,0x5
ffffffffc0200282:	6da50513          	addi	a0,a0,1754 # ffffffffc0205958 <etext+0xb4>
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
ffffffffc02002ae:	6ce50513          	addi	a0,a0,1742 # ffffffffc0205978 <etext+0xd4>
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
ffffffffc02002bc:	6f060613          	addi	a2,a2,1776 # ffffffffc02059a8 <etext+0x104>
ffffffffc02002c0:	04d00593          	li	a1,77
ffffffffc02002c4:	00005517          	auipc	a0,0x5
ffffffffc02002c8:	6fc50513          	addi	a0,a0,1788 # ffffffffc02059c0 <etext+0x11c>
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
ffffffffc02002de:	35640413          	addi	s0,s0,854 # ffffffffc0207630 <commands>
ffffffffc02002e2:	00007497          	auipc	s1,0x7
ffffffffc02002e6:	39648493          	addi	s1,s1,918 # ffffffffc0207678 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ea:	6410                	ld	a2,8(s0)
ffffffffc02002ec:	600c                	ld	a1,0(s0)
ffffffffc02002ee:	00005517          	auipc	a0,0x5
ffffffffc02002f2:	6ea50513          	addi	a0,a0,1770 # ffffffffc02059d8 <etext+0x134>
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
ffffffffc0200336:	6b650513          	addi	a0,a0,1718 # ffffffffc02059e8 <etext+0x144>
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
ffffffffc020034e:	6c650513          	addi	a0,a0,1734 # ffffffffc0205a10 <etext+0x16c>
ffffffffc0200352:	e47ff0ef          	jal	ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc0200356:	000a0563          	beqz	s4,ffffffffc0200360 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020035a:	8552                	mv	a0,s4
ffffffffc020035c:	792000ef          	jal	ffffffffc0200aee <print_trapframe>
ffffffffc0200360:	00007a97          	auipc	s5,0x7
ffffffffc0200364:	2d0a8a93          	addi	s5,s5,720 # ffffffffc0207630 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020036a:	00005517          	auipc	a0,0x5
ffffffffc020036e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0205a38 <etext+0x194>
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
ffffffffc020038c:	2a848493          	addi	s1,s1,680 # ffffffffc0207630 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200390:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	6088                	ld	a0,0(s1)
ffffffffc0200396:	476050ef          	jal	ffffffffc020580c <strcmp>
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
ffffffffc02003ac:	6c050513          	addi	a0,a0,1728 # ffffffffc0205a68 <etext+0x1c4>
ffffffffc02003b0:	de9ff0ef          	jal	ffffffffc0200198 <cprintf>
    return 0;
ffffffffc02003b4:	bf5d                	j	ffffffffc020036a <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b6:	00005517          	auipc	a0,0x5
ffffffffc02003ba:	68a50513          	addi	a0,a0,1674 # ffffffffc0205a40 <etext+0x19c>
ffffffffc02003be:	4aa050ef          	jal	ffffffffc0205868 <strchr>
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
ffffffffc02003fc:	64850513          	addi	a0,a0,1608 # ffffffffc0205a40 <etext+0x19c>
ffffffffc0200400:	468050ef          	jal	ffffffffc0205868 <strchr>
ffffffffc0200404:	d575                	beqz	a0,ffffffffc02003f0 <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200406:	00044583          	lbu	a1,0(s0)
ffffffffc020040a:	dda5                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc020040c:	b76d                	j	ffffffffc02003b6 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040e:	45c1                	li	a1,16
ffffffffc0200410:	00005517          	auipc	a0,0x5
ffffffffc0200414:	63850513          	addi	a0,a0,1592 # ffffffffc0205a48 <etext+0x1a4>
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
ffffffffc0200474:	6a050513          	addi	a0,a0,1696 # ffffffffc0205b10 <etext+0x26c>
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
ffffffffc0200492:	6a250513          	addi	a0,a0,1698 # ffffffffc0205b30 <etext+0x28c>
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
ffffffffc02004c6:	67650513          	addi	a0,a0,1654 # ffffffffc0205b38 <etext+0x294>
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
ffffffffc02004e8:	64c50513          	addi	a0,a0,1612 # ffffffffc0205b30 <etext+0x28c>
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
ffffffffc020051a:	64250513          	addi	a0,a0,1602 # ffffffffc0205b58 <etext+0x2b4>
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
ffffffffc02005b8:	5c450513          	addi	a0,a0,1476 # ffffffffc0205b78 <etext+0x2d4>
void dtb_init(void) {
ffffffffc02005bc:	f406                	sd	ra,40(sp)
ffffffffc02005be:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c0:	bd9ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005c4:	0000c597          	auipc	a1,0xc
ffffffffc02005c8:	a3c5b583          	ld	a1,-1476(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc02005cc:	00005517          	auipc	a0,0x5
ffffffffc02005d0:	5bc50513          	addi	a0,a0,1468 # ffffffffc0205b88 <etext+0x2e4>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005d4:	0000c417          	auipc	s0,0xc
ffffffffc02005d8:	a3440413          	addi	s0,s0,-1484 # ffffffffc020c008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005dc:	bbdff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e0:	600c                	ld	a1,0(s0)
ffffffffc02005e2:	00005517          	auipc	a0,0x5
ffffffffc02005e6:	5b650513          	addi	a0,a0,1462 # ffffffffc0205b98 <etext+0x2f4>
ffffffffc02005ea:	bafff0ef          	jal	ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005ee:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f0:	00005517          	auipc	a0,0x5
ffffffffc02005f4:	5c050513          	addi	a0,a0,1472 # ffffffffc0205bb0 <etext+0x30c>
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
ffffffffc02006e6:	59650513          	addi	a0,a0,1430 # ffffffffc0205c78 <etext+0x3d4>
ffffffffc02006ea:	aafff0ef          	jal	ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006ee:	64e2                	ld	s1,24(sp)
ffffffffc02006f0:	6942                	ld	s2,16(sp)
ffffffffc02006f2:	00005517          	auipc	a0,0x5
ffffffffc02006f6:	5be50513          	addi	a0,a0,1470 # ffffffffc0205cb0 <etext+0x40c>
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
ffffffffc020070a:	4ca50513          	addi	a0,a0,1226 # ffffffffc0205bd0 <etext+0x32c>
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
ffffffffc020074c:	07a050ef          	jal	ffffffffc02057c6 <strlen>
ffffffffc0200750:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200752:	4619                	li	a2,6
ffffffffc0200754:	8522                	mv	a0,s0
ffffffffc0200756:	00005597          	auipc	a1,0x5
ffffffffc020075a:	4a258593          	addi	a1,a1,1186 # ffffffffc0205bf8 <etext+0x354>
ffffffffc020075e:	0e2050ef          	jal	ffffffffc0205840 <strncmp>
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
ffffffffc0200786:	47e58593          	addi	a1,a1,1150 # ffffffffc0205c00 <etext+0x35c>
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
ffffffffc02007b8:	054050ef          	jal	ffffffffc020580c <strcmp>
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
ffffffffc02007dc:	43050513          	addi	a0,a0,1072 # ffffffffc0205c08 <etext+0x364>
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
ffffffffc02008a6:	38650513          	addi	a0,a0,902 # ffffffffc0205c28 <etext+0x384>
ffffffffc02008aa:	8efff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008ae:	01445613          	srli	a2,s0,0x14
ffffffffc02008b2:	85a2                	mv	a1,s0
ffffffffc02008b4:	00005517          	auipc	a0,0x5
ffffffffc02008b8:	38c50513          	addi	a0,a0,908 # ffffffffc0205c40 <etext+0x39c>
ffffffffc02008bc:	8ddff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c0:	009405b3          	add	a1,s0,s1
ffffffffc02008c4:	15fd                	addi	a1,a1,-1
ffffffffc02008c6:	00005517          	auipc	a0,0x5
ffffffffc02008ca:	39a50513          	addi	a0,a0,922 # ffffffffc0205c60 <etext+0x3bc>
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
ffffffffc020090e:	4b278793          	addi	a5,a5,1202 # ffffffffc0200dbc <__alltraps>
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
ffffffffc020092c:	3a050513          	addi	a0,a0,928 # ffffffffc0205cc8 <etext+0x424>
{
ffffffffc0200930:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200932:	867ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200936:	640c                	ld	a1,8(s0)
ffffffffc0200938:	00005517          	auipc	a0,0x5
ffffffffc020093c:	3a850513          	addi	a0,a0,936 # ffffffffc0205ce0 <etext+0x43c>
ffffffffc0200940:	859ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200944:	680c                	ld	a1,16(s0)
ffffffffc0200946:	00005517          	auipc	a0,0x5
ffffffffc020094a:	3b250513          	addi	a0,a0,946 # ffffffffc0205cf8 <etext+0x454>
ffffffffc020094e:	84bff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200952:	6c0c                	ld	a1,24(s0)
ffffffffc0200954:	00005517          	auipc	a0,0x5
ffffffffc0200958:	3bc50513          	addi	a0,a0,956 # ffffffffc0205d10 <etext+0x46c>
ffffffffc020095c:	83dff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200960:	700c                	ld	a1,32(s0)
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	3c650513          	addi	a0,a0,966 # ffffffffc0205d28 <etext+0x484>
ffffffffc020096a:	82fff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020096e:	740c                	ld	a1,40(s0)
ffffffffc0200970:	00005517          	auipc	a0,0x5
ffffffffc0200974:	3d050513          	addi	a0,a0,976 # ffffffffc0205d40 <etext+0x49c>
ffffffffc0200978:	821ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc020097c:	780c                	ld	a1,48(s0)
ffffffffc020097e:	00005517          	auipc	a0,0x5
ffffffffc0200982:	3da50513          	addi	a0,a0,986 # ffffffffc0205d58 <etext+0x4b4>
ffffffffc0200986:	813ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020098a:	7c0c                	ld	a1,56(s0)
ffffffffc020098c:	00005517          	auipc	a0,0x5
ffffffffc0200990:	3e450513          	addi	a0,a0,996 # ffffffffc0205d70 <etext+0x4cc>
ffffffffc0200994:	805ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200998:	602c                	ld	a1,64(s0)
ffffffffc020099a:	00005517          	auipc	a0,0x5
ffffffffc020099e:	3ee50513          	addi	a0,a0,1006 # ffffffffc0205d88 <etext+0x4e4>
ffffffffc02009a2:	ff6ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009a6:	642c                	ld	a1,72(s0)
ffffffffc02009a8:	00005517          	auipc	a0,0x5
ffffffffc02009ac:	3f850513          	addi	a0,a0,1016 # ffffffffc0205da0 <etext+0x4fc>
ffffffffc02009b0:	fe8ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009b4:	682c                	ld	a1,80(s0)
ffffffffc02009b6:	00005517          	auipc	a0,0x5
ffffffffc02009ba:	40250513          	addi	a0,a0,1026 # ffffffffc0205db8 <etext+0x514>
ffffffffc02009be:	fdaff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c2:	6c2c                	ld	a1,88(s0)
ffffffffc02009c4:	00005517          	auipc	a0,0x5
ffffffffc02009c8:	40c50513          	addi	a0,a0,1036 # ffffffffc0205dd0 <etext+0x52c>
ffffffffc02009cc:	fccff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d0:	702c                	ld	a1,96(s0)
ffffffffc02009d2:	00005517          	auipc	a0,0x5
ffffffffc02009d6:	41650513          	addi	a0,a0,1046 # ffffffffc0205de8 <etext+0x544>
ffffffffc02009da:	fbeff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009de:	742c                	ld	a1,104(s0)
ffffffffc02009e0:	00005517          	auipc	a0,0x5
ffffffffc02009e4:	42050513          	addi	a0,a0,1056 # ffffffffc0205e00 <etext+0x55c>
ffffffffc02009e8:	fb0ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009ec:	782c                	ld	a1,112(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	42a50513          	addi	a0,a0,1066 # ffffffffc0205e18 <etext+0x574>
ffffffffc02009f6:	fa2ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02009fa:	7c2c                	ld	a1,120(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	43450513          	addi	a0,a0,1076 # ffffffffc0205e30 <etext+0x58c>
ffffffffc0200a04:	f94ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a08:	604c                	ld	a1,128(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	43e50513          	addi	a0,a0,1086 # ffffffffc0205e48 <etext+0x5a4>
ffffffffc0200a12:	f86ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a16:	644c                	ld	a1,136(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	44850513          	addi	a0,a0,1096 # ffffffffc0205e60 <etext+0x5bc>
ffffffffc0200a20:	f78ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a24:	684c                	ld	a1,144(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	45250513          	addi	a0,a0,1106 # ffffffffc0205e78 <etext+0x5d4>
ffffffffc0200a2e:	f6aff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a32:	6c4c                	ld	a1,152(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	45c50513          	addi	a0,a0,1116 # ffffffffc0205e90 <etext+0x5ec>
ffffffffc0200a3c:	f5cff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a40:	704c                	ld	a1,160(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	46650513          	addi	a0,a0,1126 # ffffffffc0205ea8 <etext+0x604>
ffffffffc0200a4a:	f4eff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a4e:	744c                	ld	a1,168(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	47050513          	addi	a0,a0,1136 # ffffffffc0205ec0 <etext+0x61c>
ffffffffc0200a58:	f40ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a5c:	784c                	ld	a1,176(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	47a50513          	addi	a0,a0,1146 # ffffffffc0205ed8 <etext+0x634>
ffffffffc0200a66:	f32ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a6a:	7c4c                	ld	a1,184(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	48450513          	addi	a0,a0,1156 # ffffffffc0205ef0 <etext+0x64c>
ffffffffc0200a74:	f24ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a78:	606c                	ld	a1,192(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	48e50513          	addi	a0,a0,1166 # ffffffffc0205f08 <etext+0x664>
ffffffffc0200a82:	f16ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a86:	646c                	ld	a1,200(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	49850513          	addi	a0,a0,1176 # ffffffffc0205f20 <etext+0x67c>
ffffffffc0200a90:	f08ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a94:	686c                	ld	a1,208(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	4a250513          	addi	a0,a0,1186 # ffffffffc0205f38 <etext+0x694>
ffffffffc0200a9e:	efaff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa2:	6c6c                	ld	a1,216(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	4ac50513          	addi	a0,a0,1196 # ffffffffc0205f50 <etext+0x6ac>
ffffffffc0200aac:	eecff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab0:	706c                	ld	a1,224(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	4b650513          	addi	a0,a0,1206 # ffffffffc0205f68 <etext+0x6c4>
ffffffffc0200aba:	edeff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200abe:	746c                	ld	a1,232(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	4c050513          	addi	a0,a0,1216 # ffffffffc0205f80 <etext+0x6dc>
ffffffffc0200ac8:	ed0ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200acc:	786c                	ld	a1,240(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	4ca50513          	addi	a0,a0,1226 # ffffffffc0205f98 <etext+0x6f4>
ffffffffc0200ad6:	ec2ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ada:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200adc:	6402                	ld	s0,0(sp)
ffffffffc0200ade:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	00005517          	auipc	a0,0x5
ffffffffc0200ae4:	4d050513          	addi	a0,a0,1232 # ffffffffc0205fb0 <etext+0x70c>
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
ffffffffc0200afa:	4d250513          	addi	a0,a0,1234 # ffffffffc0205fc8 <etext+0x724>
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
ffffffffc0200b12:	4d250513          	addi	a0,a0,1234 # ffffffffc0205fe0 <etext+0x73c>
ffffffffc0200b16:	e82ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b1a:	10843583          	ld	a1,264(s0)
ffffffffc0200b1e:	00005517          	auipc	a0,0x5
ffffffffc0200b22:	4da50513          	addi	a0,a0,1242 # ffffffffc0205ff8 <etext+0x754>
ffffffffc0200b26:	e72ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b2a:	11043583          	ld	a1,272(s0)
ffffffffc0200b2e:	00005517          	auipc	a0,0x5
ffffffffc0200b32:	4e250513          	addi	a0,a0,1250 # ffffffffc0206010 <etext+0x76c>
ffffffffc0200b36:	e62ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b3a:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b3e:	6402                	ld	s0,0(sp)
ffffffffc0200b40:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b42:	00005517          	auipc	a0,0x5
ffffffffc0200b46:	4de50513          	addi	a0,a0,1246 # ffffffffc0206020 <etext+0x77c>
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
ffffffffc0200b5a:	08f76263          	bltu	a4,a5,ffffffffc0200bde <interrupt_handler+0x8e>
ffffffffc0200b5e:	00007717          	auipc	a4,0x7
ffffffffc0200b62:	b1a70713          	addi	a4,a4,-1254 # ffffffffc0207678 <commands+0x48>
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
ffffffffc0200b74:	52850513          	addi	a0,a0,1320 # ffffffffc0206098 <etext+0x7f4>
ffffffffc0200b78:	e20ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b7c:	00005517          	auipc	a0,0x5
ffffffffc0200b80:	4fc50513          	addi	a0,a0,1276 # ffffffffc0206078 <etext+0x7d4>
ffffffffc0200b84:	e14ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b88:	00005517          	auipc	a0,0x5
ffffffffc0200b8c:	4b050513          	addi	a0,a0,1200 # ffffffffc0206038 <etext+0x794>
ffffffffc0200b90:	e08ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b94:	00005517          	auipc	a0,0x5
ffffffffc0200b98:	4c450513          	addi	a0,a0,1220 # ffffffffc0206058 <etext+0x7b4>
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
ffffffffc0200bb0:	6398                	ld	a4,0(a5)
        static int num=0;
        if(ticks==TICK_NUM){
ffffffffc0200bb2:	06400693          	li	a3,100
        ticks++;
ffffffffc0200bb6:	0705                	addi	a4,a4,1
ffffffffc0200bb8:	e398                	sd	a4,0(a5)
        if(ticks==TICK_NUM){
ffffffffc0200bba:	638c                	ld	a1,0(a5)
ffffffffc0200bbc:	02d58563          	beq	a1,a3,ffffffffc0200be6 <interrupt_handler+0x96>
        if(num==10){
            sbi_shutdown();
        }
        // lab6: YOUR CODE  (update LAB3 steps)
        //  在时钟中断时调用调度器的 sched_class_proc_tick 函数
        if (current) sched_class_proc_tick(current);
ffffffffc0200bc0:	000b5517          	auipc	a0,0xb5
ffffffffc0200bc4:	ae053503          	ld	a0,-1312(a0) # ffffffffc02b56a0 <current>
ffffffffc0200bc8:	cd01                	beqz	a0,ffffffffc0200be0 <interrupt_handler+0x90>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bca:	60a2                	ld	ra,8(sp)
ffffffffc0200bcc:	0141                	addi	sp,sp,16
        if (current) sched_class_proc_tick(current);
ffffffffc0200bce:	4f00406f          	j	ffffffffc02050be <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bd2:	00005517          	auipc	a0,0x5
ffffffffc0200bd6:	53650513          	addi	a0,a0,1334 # ffffffffc0206108 <etext+0x864>
ffffffffc0200bda:	dbeff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200bde:	bf01                	j	ffffffffc0200aee <print_trapframe>
}
ffffffffc0200be0:	60a2                	ld	ra,8(sp)
ffffffffc0200be2:	0141                	addi	sp,sp,16
ffffffffc0200be4:	8082                	ret
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200be6:	00005517          	auipc	a0,0x5
ffffffffc0200bea:	4d250513          	addi	a0,a0,1234 # ffffffffc02060b8 <etext+0x814>
ffffffffc0200bee:	daaff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("End of Test.\n");
ffffffffc0200bf2:	00005517          	auipc	a0,0x5
ffffffffc0200bf6:	4d650513          	addi	a0,a0,1238 # ffffffffc02060c8 <etext+0x824>
ffffffffc0200bfa:	d9eff0ef          	jal	ffffffffc0200198 <cprintf>
    panic("EOT: kernel seems ok.");
ffffffffc0200bfe:	00005617          	auipc	a2,0x5
ffffffffc0200c02:	4da60613          	addi	a2,a2,1242 # ffffffffc02060d8 <etext+0x834>
ffffffffc0200c06:	45ed                	li	a1,27
ffffffffc0200c08:	00005517          	auipc	a0,0x5
ffffffffc0200c0c:	4e850513          	addi	a0,a0,1256 # ffffffffc02060f0 <etext+0x84c>
ffffffffc0200c10:	83bff0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0200c14 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c14:	11853783          	ld	a5,280(a0)
ffffffffc0200c18:	473d                	li	a4,15
ffffffffc0200c1a:	10f76e63          	bltu	a4,a5,ffffffffc0200d36 <exception_handler+0x122>
ffffffffc0200c1e:	00007717          	auipc	a4,0x7
ffffffffc0200c22:	a8a70713          	addi	a4,a4,-1398 # ffffffffc02076a8 <commands+0x78>
ffffffffc0200c26:	078a                	slli	a5,a5,0x2
ffffffffc0200c28:	97ba                	add	a5,a5,a4
ffffffffc0200c2a:	439c                	lw	a5,0(a5)
{
ffffffffc0200c2c:	1101                	addi	sp,sp,-32
ffffffffc0200c2e:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c30:	97ba                	add	a5,a5,a4
ffffffffc0200c32:	86aa                	mv	a3,a0
ffffffffc0200c34:	8782                	jr	a5
ffffffffc0200c36:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c38:	00005517          	auipc	a0,0x5
ffffffffc0200c3c:	5c050513          	addi	a0,a0,1472 # ffffffffc02061f8 <etext+0x954>
ffffffffc0200c40:	d58ff0ef          	jal	ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200c44:	66a2                	ld	a3,8(sp)
ffffffffc0200c46:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c4a:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200c4c:	0791                	addi	a5,a5,4
ffffffffc0200c4e:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200c52:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200c54:	7120406f          	j	ffffffffc0205366 <syscall>
}
ffffffffc0200c58:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c5a:	00005517          	auipc	a0,0x5
ffffffffc0200c5e:	5be50513          	addi	a0,a0,1470 # ffffffffc0206218 <etext+0x974>
}
ffffffffc0200c62:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c64:	d34ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c68:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c6a:	00005517          	auipc	a0,0x5
ffffffffc0200c6e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0206238 <etext+0x994>
}
ffffffffc0200c72:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200c74:	d24ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c78:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200c7a:	00005517          	auipc	a0,0x5
ffffffffc0200c7e:	5de50513          	addi	a0,a0,1502 # ffffffffc0206258 <etext+0x9b4>
}
ffffffffc0200c82:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200c84:	d14ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c88:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200c8a:	00005517          	auipc	a0,0x5
ffffffffc0200c8e:	5e650513          	addi	a0,a0,1510 # ffffffffc0206270 <etext+0x9cc>
}
ffffffffc0200c92:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200c94:	d04ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c98:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200c9a:	00005517          	auipc	a0,0x5
ffffffffc0200c9e:	5ee50513          	addi	a0,a0,1518 # ffffffffc0206288 <etext+0x9e4>
}
ffffffffc0200ca2:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200ca4:	cf4ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200ca8:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200caa:	00005517          	auipc	a0,0x5
ffffffffc0200cae:	47e50513          	addi	a0,a0,1150 # ffffffffc0206128 <etext+0x884>
}
ffffffffc0200cb2:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200cb4:	ce4ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cb8:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200cba:	00005517          	auipc	a0,0x5
ffffffffc0200cbe:	48e50513          	addi	a0,a0,1166 # ffffffffc0206148 <etext+0x8a4>
}
ffffffffc0200cc2:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200cc4:	cd4ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cc8:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200cca:	00005517          	auipc	a0,0x5
ffffffffc0200cce:	49e50513          	addi	a0,a0,1182 # ffffffffc0206168 <etext+0x8c4>
}
ffffffffc0200cd2:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200cd4:	cc4ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cd8:	60e2                	ld	ra,24(sp)
        cprintf("Breakpoint\n");
ffffffffc0200cda:	00005517          	auipc	a0,0x5
ffffffffc0200cde:	4a650513          	addi	a0,a0,1190 # ffffffffc0206180 <etext+0x8dc>
}
ffffffffc0200ce2:	6105                	addi	sp,sp,32
        cprintf("Breakpoint\n");
ffffffffc0200ce4:	cb4ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200ce8:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200cea:	00005517          	auipc	a0,0x5
ffffffffc0200cee:	4a650513          	addi	a0,a0,1190 # ffffffffc0206190 <etext+0x8ec>
}
ffffffffc0200cf2:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200cf4:	ca4ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cf8:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200cfa:	00005517          	auipc	a0,0x5
ffffffffc0200cfe:	4b650513          	addi	a0,a0,1206 # ffffffffc02061b0 <etext+0x90c>
}
ffffffffc0200d02:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d04:	c94ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d08:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d0a:	00005517          	auipc	a0,0x5
ffffffffc0200d0e:	4d650513          	addi	a0,a0,1238 # ffffffffc02061e0 <etext+0x93c>
}
ffffffffc0200d12:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d14:	c84ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d18:	60e2                	ld	ra,24(sp)
ffffffffc0200d1a:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d1c:	bbc9                	j	ffffffffc0200aee <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d1e:	00005617          	auipc	a2,0x5
ffffffffc0200d22:	4aa60613          	addi	a2,a2,1194 # ffffffffc02061c8 <etext+0x924>
ffffffffc0200d26:	0c200593          	li	a1,194
ffffffffc0200d2a:	00005517          	auipc	a0,0x5
ffffffffc0200d2e:	3c650513          	addi	a0,a0,966 # ffffffffc02060f0 <etext+0x84c>
ffffffffc0200d32:	f18ff0ef          	jal	ffffffffc020044a <__panic>
        print_trapframe(tf);
ffffffffc0200d36:	bb65                	j	ffffffffc0200aee <print_trapframe>

ffffffffc0200d38 <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d38:	000b5717          	auipc	a4,0xb5
ffffffffc0200d3c:	96873703          	ld	a4,-1688(a4) # ffffffffc02b56a0 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d40:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d44:	cf21                	beqz	a4,ffffffffc0200d9c <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d46:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d4a:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200d4e:	1101                	addi	sp,sp,-32
ffffffffc0200d50:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d52:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200d56:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d58:	e432                	sd	a2,8(sp)
ffffffffc0200d5a:	e042                	sd	a6,0(sp)
ffffffffc0200d5c:	0205c763          	bltz	a1,ffffffffc0200d8a <trap+0x52>
        exception_handler(tf);
ffffffffc0200d60:	eb5ff0ef          	jal	ffffffffc0200c14 <exception_handler>
ffffffffc0200d64:	6622                	ld	a2,8(sp)
ffffffffc0200d66:	6802                	ld	a6,0(sp)
ffffffffc0200d68:	000b5697          	auipc	a3,0xb5
ffffffffc0200d6c:	93868693          	addi	a3,a3,-1736 # ffffffffc02b56a0 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200d70:	6298                	ld	a4,0(a3)
ffffffffc0200d72:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200d76:	e619                	bnez	a2,ffffffffc0200d84 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200d78:	0b072783          	lw	a5,176(a4)
ffffffffc0200d7c:	8b85                	andi	a5,a5,1
ffffffffc0200d7e:	e79d                	bnez	a5,ffffffffc0200dac <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200d80:	6f1c                	ld	a5,24(a4)
ffffffffc0200d82:	e38d                	bnez	a5,ffffffffc0200da4 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200d84:	60e2                	ld	ra,24(sp)
ffffffffc0200d86:	6105                	addi	sp,sp,32
ffffffffc0200d88:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200d8a:	dc7ff0ef          	jal	ffffffffc0200b50 <interrupt_handler>
ffffffffc0200d8e:	6802                	ld	a6,0(sp)
ffffffffc0200d90:	6622                	ld	a2,8(sp)
ffffffffc0200d92:	000b5697          	auipc	a3,0xb5
ffffffffc0200d96:	90e68693          	addi	a3,a3,-1778 # ffffffffc02b56a0 <current>
ffffffffc0200d9a:	bfd9                	j	ffffffffc0200d70 <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d9c:	0005c363          	bltz	a1,ffffffffc0200da2 <trap+0x6a>
        exception_handler(tf);
ffffffffc0200da0:	bd95                	j	ffffffffc0200c14 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200da2:	b37d                	j	ffffffffc0200b50 <interrupt_handler>
}
ffffffffc0200da4:	60e2                	ld	ra,24(sp)
ffffffffc0200da6:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200da8:	48a0406f          	j	ffffffffc0205232 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200dac:	555d                	li	a0,-9
ffffffffc0200dae:	4ee030ef          	jal	ffffffffc020429c <do_exit>
            if (current->need_resched)
ffffffffc0200db2:	000b5717          	auipc	a4,0xb5
ffffffffc0200db6:	8ee73703          	ld	a4,-1810(a4) # ffffffffc02b56a0 <current>
ffffffffc0200dba:	b7d9                	j	ffffffffc0200d80 <trap+0x48>

ffffffffc0200dbc <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200dbc:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200dc0:	00011463          	bnez	sp,ffffffffc0200dc8 <__alltraps+0xc>
ffffffffc0200dc4:	14002173          	csrr	sp,sscratch
ffffffffc0200dc8:	712d                	addi	sp,sp,-288
ffffffffc0200dca:	e002                	sd	zero,0(sp)
ffffffffc0200dcc:	e406                	sd	ra,8(sp)
ffffffffc0200dce:	ec0e                	sd	gp,24(sp)
ffffffffc0200dd0:	f012                	sd	tp,32(sp)
ffffffffc0200dd2:	f416                	sd	t0,40(sp)
ffffffffc0200dd4:	f81a                	sd	t1,48(sp)
ffffffffc0200dd6:	fc1e                	sd	t2,56(sp)
ffffffffc0200dd8:	e0a2                	sd	s0,64(sp)
ffffffffc0200dda:	e4a6                	sd	s1,72(sp)
ffffffffc0200ddc:	e8aa                	sd	a0,80(sp)
ffffffffc0200dde:	ecae                	sd	a1,88(sp)
ffffffffc0200de0:	f0b2                	sd	a2,96(sp)
ffffffffc0200de2:	f4b6                	sd	a3,104(sp)
ffffffffc0200de4:	f8ba                	sd	a4,112(sp)
ffffffffc0200de6:	fcbe                	sd	a5,120(sp)
ffffffffc0200de8:	e142                	sd	a6,128(sp)
ffffffffc0200dea:	e546                	sd	a7,136(sp)
ffffffffc0200dec:	e94a                	sd	s2,144(sp)
ffffffffc0200dee:	ed4e                	sd	s3,152(sp)
ffffffffc0200df0:	f152                	sd	s4,160(sp)
ffffffffc0200df2:	f556                	sd	s5,168(sp)
ffffffffc0200df4:	f95a                	sd	s6,176(sp)
ffffffffc0200df6:	fd5e                	sd	s7,184(sp)
ffffffffc0200df8:	e1e2                	sd	s8,192(sp)
ffffffffc0200dfa:	e5e6                	sd	s9,200(sp)
ffffffffc0200dfc:	e9ea                	sd	s10,208(sp)
ffffffffc0200dfe:	edee                	sd	s11,216(sp)
ffffffffc0200e00:	f1f2                	sd	t3,224(sp)
ffffffffc0200e02:	f5f6                	sd	t4,232(sp)
ffffffffc0200e04:	f9fa                	sd	t5,240(sp)
ffffffffc0200e06:	fdfe                	sd	t6,248(sp)
ffffffffc0200e08:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e0c:	100024f3          	csrr	s1,sstatus
ffffffffc0200e10:	14102973          	csrr	s2,sepc
ffffffffc0200e14:	143029f3          	csrr	s3,stval
ffffffffc0200e18:	14202a73          	csrr	s4,scause
ffffffffc0200e1c:	e822                	sd	s0,16(sp)
ffffffffc0200e1e:	e226                	sd	s1,256(sp)
ffffffffc0200e20:	e64a                	sd	s2,264(sp)
ffffffffc0200e22:	ea4e                	sd	s3,272(sp)
ffffffffc0200e24:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e26:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e28:	f11ff0ef          	jal	ffffffffc0200d38 <trap>

ffffffffc0200e2c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e2c:	6492                	ld	s1,256(sp)
ffffffffc0200e2e:	6932                	ld	s2,264(sp)
ffffffffc0200e30:	1004f413          	andi	s0,s1,256
ffffffffc0200e34:	e401                	bnez	s0,ffffffffc0200e3c <__trapret+0x10>
ffffffffc0200e36:	1200                	addi	s0,sp,288
ffffffffc0200e38:	14041073          	csrw	sscratch,s0
ffffffffc0200e3c:	10049073          	csrw	sstatus,s1
ffffffffc0200e40:	14191073          	csrw	sepc,s2
ffffffffc0200e44:	60a2                	ld	ra,8(sp)
ffffffffc0200e46:	61e2                	ld	gp,24(sp)
ffffffffc0200e48:	7202                	ld	tp,32(sp)
ffffffffc0200e4a:	72a2                	ld	t0,40(sp)
ffffffffc0200e4c:	7342                	ld	t1,48(sp)
ffffffffc0200e4e:	73e2                	ld	t2,56(sp)
ffffffffc0200e50:	6406                	ld	s0,64(sp)
ffffffffc0200e52:	64a6                	ld	s1,72(sp)
ffffffffc0200e54:	6546                	ld	a0,80(sp)
ffffffffc0200e56:	65e6                	ld	a1,88(sp)
ffffffffc0200e58:	7606                	ld	a2,96(sp)
ffffffffc0200e5a:	76a6                	ld	a3,104(sp)
ffffffffc0200e5c:	7746                	ld	a4,112(sp)
ffffffffc0200e5e:	77e6                	ld	a5,120(sp)
ffffffffc0200e60:	680a                	ld	a6,128(sp)
ffffffffc0200e62:	68aa                	ld	a7,136(sp)
ffffffffc0200e64:	694a                	ld	s2,144(sp)
ffffffffc0200e66:	69ea                	ld	s3,152(sp)
ffffffffc0200e68:	7a0a                	ld	s4,160(sp)
ffffffffc0200e6a:	7aaa                	ld	s5,168(sp)
ffffffffc0200e6c:	7b4a                	ld	s6,176(sp)
ffffffffc0200e6e:	7bea                	ld	s7,184(sp)
ffffffffc0200e70:	6c0e                	ld	s8,192(sp)
ffffffffc0200e72:	6cae                	ld	s9,200(sp)
ffffffffc0200e74:	6d4e                	ld	s10,208(sp)
ffffffffc0200e76:	6dee                	ld	s11,216(sp)
ffffffffc0200e78:	7e0e                	ld	t3,224(sp)
ffffffffc0200e7a:	7eae                	ld	t4,232(sp)
ffffffffc0200e7c:	7f4e                	ld	t5,240(sp)
ffffffffc0200e7e:	7fee                	ld	t6,248(sp)
ffffffffc0200e80:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200e82:	10200073          	sret

ffffffffc0200e86 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200e86:	812a                	mv	sp,a0
ffffffffc0200e88:	b755                	j	ffffffffc0200e2c <__trapret>

ffffffffc0200e8a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e8a:	000b0797          	auipc	a5,0xb0
ffffffffc0200e8e:	75e78793          	addi	a5,a5,1886 # ffffffffc02b15e8 <free_area>
ffffffffc0200e92:	e79c                	sd	a5,8(a5)
ffffffffc0200e94:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e96:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e9a:	8082                	ret

ffffffffc0200e9c <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200e9c:	000b0517          	auipc	a0,0xb0
ffffffffc0200ea0:	75c56503          	lwu	a0,1884(a0) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc0200ea4:	8082                	ret

ffffffffc0200ea6 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200ea6:	711d                	addi	sp,sp,-96
ffffffffc0200ea8:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200eaa:	000b0917          	auipc	s2,0xb0
ffffffffc0200eae:	73e90913          	addi	s2,s2,1854 # ffffffffc02b15e8 <free_area>
ffffffffc0200eb2:	00893783          	ld	a5,8(s2)
ffffffffc0200eb6:	ec86                	sd	ra,88(sp)
ffffffffc0200eb8:	e8a2                	sd	s0,80(sp)
ffffffffc0200eba:	e4a6                	sd	s1,72(sp)
ffffffffc0200ebc:	fc4e                	sd	s3,56(sp)
ffffffffc0200ebe:	f852                	sd	s4,48(sp)
ffffffffc0200ec0:	f456                	sd	s5,40(sp)
ffffffffc0200ec2:	f05a                	sd	s6,32(sp)
ffffffffc0200ec4:	ec5e                	sd	s7,24(sp)
ffffffffc0200ec6:	e862                	sd	s8,16(sp)
ffffffffc0200ec8:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200eca:	2f278363          	beq	a5,s2,ffffffffc02011b0 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200ece:	4401                	li	s0,0
ffffffffc0200ed0:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ed2:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ed6:	8b09                	andi	a4,a4,2
ffffffffc0200ed8:	2e070063          	beqz	a4,ffffffffc02011b8 <default_check+0x312>
        count++, total += p->property;
ffffffffc0200edc:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ee0:	679c                	ld	a5,8(a5)
ffffffffc0200ee2:	2485                	addiw	s1,s1,1
ffffffffc0200ee4:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ee6:	ff2796e3          	bne	a5,s2,ffffffffc0200ed2 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200eea:	89a2                	mv	s3,s0
ffffffffc0200eec:	741000ef          	jal	ffffffffc0201e2c <nr_free_pages>
ffffffffc0200ef0:	73351463          	bne	a0,s3,ffffffffc0201618 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ef4:	4505                	li	a0,1
ffffffffc0200ef6:	6c5000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0200efa:	8a2a                	mv	s4,a0
ffffffffc0200efc:	44050e63          	beqz	a0,ffffffffc0201358 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f00:	4505                	li	a0,1
ffffffffc0200f02:	6b9000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0200f06:	89aa                	mv	s3,a0
ffffffffc0200f08:	72050863          	beqz	a0,ffffffffc0201638 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f0c:	4505                	li	a0,1
ffffffffc0200f0e:	6ad000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0200f12:	8aaa                	mv	s5,a0
ffffffffc0200f14:	4c050263          	beqz	a0,ffffffffc02013d8 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f18:	40a987b3          	sub	a5,s3,a0
ffffffffc0200f1c:	40aa0733          	sub	a4,s4,a0
ffffffffc0200f20:	0017b793          	seqz	a5,a5
ffffffffc0200f24:	00173713          	seqz	a4,a4
ffffffffc0200f28:	8fd9                	or	a5,a5,a4
ffffffffc0200f2a:	30079763          	bnez	a5,ffffffffc0201238 <default_check+0x392>
ffffffffc0200f2e:	313a0563          	beq	s4,s3,ffffffffc0201238 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f32:	000a2783          	lw	a5,0(s4)
ffffffffc0200f36:	2a079163          	bnez	a5,ffffffffc02011d8 <default_check+0x332>
ffffffffc0200f3a:	0009a783          	lw	a5,0(s3)
ffffffffc0200f3e:	28079d63          	bnez	a5,ffffffffc02011d8 <default_check+0x332>
ffffffffc0200f42:	411c                	lw	a5,0(a0)
ffffffffc0200f44:	28079a63          	bnez	a5,ffffffffc02011d8 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200f48:	000b4797          	auipc	a5,0xb4
ffffffffc0200f4c:	7487b783          	ld	a5,1864(a5) # ffffffffc02b5690 <pages>
ffffffffc0200f50:	00007617          	auipc	a2,0x7
ffffffffc0200f54:	1f063603          	ld	a2,496(a2) # ffffffffc0208140 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f58:	000b4697          	auipc	a3,0xb4
ffffffffc0200f5c:	7306b683          	ld	a3,1840(a3) # ffffffffc02b5688 <npage>
ffffffffc0200f60:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f64:	8719                	srai	a4,a4,0x6
ffffffffc0200f66:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f68:	0732                	slli	a4,a4,0xc
ffffffffc0200f6a:	06b2                	slli	a3,a3,0xc
ffffffffc0200f6c:	2ad77663          	bgeu	a4,a3,ffffffffc0201218 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0200f70:	40f98733          	sub	a4,s3,a5
ffffffffc0200f74:	8719                	srai	a4,a4,0x6
ffffffffc0200f76:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f78:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f7a:	4cd77f63          	bgeu	a4,a3,ffffffffc0201458 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc0200f7e:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f82:	8799                	srai	a5,a5,0x6
ffffffffc0200f84:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f86:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f88:	32d7f863          	bgeu	a5,a3,ffffffffc02012b8 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc0200f8c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f8e:	00093c03          	ld	s8,0(s2)
ffffffffc0200f92:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f96:	000b0b17          	auipc	s6,0xb0
ffffffffc0200f9a:	662b2b03          	lw	s6,1634(s6) # ffffffffc02b15f8 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200f9e:	01293023          	sd	s2,0(s2)
ffffffffc0200fa2:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200fa6:	000b0797          	auipc	a5,0xb0
ffffffffc0200faa:	6407a923          	sw	zero,1618(a5) # ffffffffc02b15f8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200fae:	60d000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0200fb2:	2e051363          	bnez	a0,ffffffffc0201298 <default_check+0x3f2>
    free_page(p0);
ffffffffc0200fb6:	8552                	mv	a0,s4
ffffffffc0200fb8:	4585                	li	a1,1
ffffffffc0200fba:	63b000ef          	jal	ffffffffc0201df4 <free_pages>
    free_page(p1);
ffffffffc0200fbe:	854e                	mv	a0,s3
ffffffffc0200fc0:	4585                	li	a1,1
ffffffffc0200fc2:	633000ef          	jal	ffffffffc0201df4 <free_pages>
    free_page(p2);
ffffffffc0200fc6:	8556                	mv	a0,s5
ffffffffc0200fc8:	4585                	li	a1,1
ffffffffc0200fca:	62b000ef          	jal	ffffffffc0201df4 <free_pages>
    assert(nr_free == 3);
ffffffffc0200fce:	000b0717          	auipc	a4,0xb0
ffffffffc0200fd2:	62a72703          	lw	a4,1578(a4) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc0200fd6:	478d                	li	a5,3
ffffffffc0200fd8:	2af71063          	bne	a4,a5,ffffffffc0201278 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fdc:	4505                	li	a0,1
ffffffffc0200fde:	5dd000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0200fe2:	89aa                	mv	s3,a0
ffffffffc0200fe4:	26050a63          	beqz	a0,ffffffffc0201258 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fe8:	4505                	li	a0,1
ffffffffc0200fea:	5d1000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0200fee:	8aaa                	mv	s5,a0
ffffffffc0200ff0:	3c050463          	beqz	a0,ffffffffc02013b8 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ff4:	4505                	li	a0,1
ffffffffc0200ff6:	5c5000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0200ffa:	8a2a                	mv	s4,a0
ffffffffc0200ffc:	38050e63          	beqz	a0,ffffffffc0201398 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc0201000:	4505                	li	a0,1
ffffffffc0201002:	5b9000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0201006:	36051963          	bnez	a0,ffffffffc0201378 <default_check+0x4d2>
    free_page(p0);
ffffffffc020100a:	4585                	li	a1,1
ffffffffc020100c:	854e                	mv	a0,s3
ffffffffc020100e:	5e7000ef          	jal	ffffffffc0201df4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201012:	00893783          	ld	a5,8(s2)
ffffffffc0201016:	1f278163          	beq	a5,s2,ffffffffc02011f8 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc020101a:	4505                	li	a0,1
ffffffffc020101c:	59f000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0201020:	8caa                	mv	s9,a0
ffffffffc0201022:	30a99b63          	bne	s3,a0,ffffffffc0201338 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc0201026:	4505                	li	a0,1
ffffffffc0201028:	593000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc020102c:	2e051663          	bnez	a0,ffffffffc0201318 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc0201030:	000b0797          	auipc	a5,0xb0
ffffffffc0201034:	5c87a783          	lw	a5,1480(a5) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc0201038:	2c079063          	bnez	a5,ffffffffc02012f8 <default_check+0x452>
    free_page(p);
ffffffffc020103c:	8566                	mv	a0,s9
ffffffffc020103e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201040:	01893023          	sd	s8,0(s2)
ffffffffc0201044:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0201048:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc020104c:	5a9000ef          	jal	ffffffffc0201df4 <free_pages>
    free_page(p1);
ffffffffc0201050:	8556                	mv	a0,s5
ffffffffc0201052:	4585                	li	a1,1
ffffffffc0201054:	5a1000ef          	jal	ffffffffc0201df4 <free_pages>
    free_page(p2);
ffffffffc0201058:	8552                	mv	a0,s4
ffffffffc020105a:	4585                	li	a1,1
ffffffffc020105c:	599000ef          	jal	ffffffffc0201df4 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201060:	4515                	li	a0,5
ffffffffc0201062:	559000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0201066:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201068:	26050863          	beqz	a0,ffffffffc02012d8 <default_check+0x432>
ffffffffc020106c:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc020106e:	8b89                	andi	a5,a5,2
ffffffffc0201070:	54079463          	bnez	a5,ffffffffc02015b8 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201074:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201076:	00093b83          	ld	s7,0(s2)
ffffffffc020107a:	00893b03          	ld	s6,8(s2)
ffffffffc020107e:	01293023          	sd	s2,0(s2)
ffffffffc0201082:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0201086:	535000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc020108a:	50051763          	bnez	a0,ffffffffc0201598 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020108e:	08098a13          	addi	s4,s3,128
ffffffffc0201092:	8552                	mv	a0,s4
ffffffffc0201094:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201096:	000b0c17          	auipc	s8,0xb0
ffffffffc020109a:	562c2c03          	lw	s8,1378(s8) # ffffffffc02b15f8 <free_area+0x10>
    nr_free = 0;
ffffffffc020109e:	000b0797          	auipc	a5,0xb0
ffffffffc02010a2:	5407ad23          	sw	zero,1370(a5) # ffffffffc02b15f8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010a6:	54f000ef          	jal	ffffffffc0201df4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02010aa:	4511                	li	a0,4
ffffffffc02010ac:	50f000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc02010b0:	4c051463          	bnez	a0,ffffffffc0201578 <default_check+0x6d2>
ffffffffc02010b4:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02010b8:	8b89                	andi	a5,a5,2
ffffffffc02010ba:	48078f63          	beqz	a5,ffffffffc0201558 <default_check+0x6b2>
ffffffffc02010be:	0909a503          	lw	a0,144(s3)
ffffffffc02010c2:	478d                	li	a5,3
ffffffffc02010c4:	48f51a63          	bne	a0,a5,ffffffffc0201558 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010c8:	4f3000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc02010cc:	8aaa                	mv	s5,a0
ffffffffc02010ce:	46050563          	beqz	a0,ffffffffc0201538 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc02010d2:	4505                	li	a0,1
ffffffffc02010d4:	4e7000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc02010d8:	44051063          	bnez	a0,ffffffffc0201518 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc02010dc:	415a1e63          	bne	s4,s5,ffffffffc02014f8 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010e0:	4585                	li	a1,1
ffffffffc02010e2:	854e                	mv	a0,s3
ffffffffc02010e4:	511000ef          	jal	ffffffffc0201df4 <free_pages>
    free_pages(p1, 3);
ffffffffc02010e8:	8552                	mv	a0,s4
ffffffffc02010ea:	458d                	li	a1,3
ffffffffc02010ec:	509000ef          	jal	ffffffffc0201df4 <free_pages>
ffffffffc02010f0:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010f4:	8b89                	andi	a5,a5,2
ffffffffc02010f6:	3e078163          	beqz	a5,ffffffffc02014d8 <default_check+0x632>
ffffffffc02010fa:	0109aa83          	lw	s5,16(s3)
ffffffffc02010fe:	4785                	li	a5,1
ffffffffc0201100:	3cfa9c63          	bne	s5,a5,ffffffffc02014d8 <default_check+0x632>
ffffffffc0201104:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201108:	8b89                	andi	a5,a5,2
ffffffffc020110a:	3a078763          	beqz	a5,ffffffffc02014b8 <default_check+0x612>
ffffffffc020110e:	010a2703          	lw	a4,16(s4)
ffffffffc0201112:	478d                	li	a5,3
ffffffffc0201114:	3af71263          	bne	a4,a5,ffffffffc02014b8 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201118:	8556                	mv	a0,s5
ffffffffc020111a:	4a1000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc020111e:	36a99d63          	bne	s3,a0,ffffffffc0201498 <default_check+0x5f2>
    free_page(p0);
ffffffffc0201122:	85d6                	mv	a1,s5
ffffffffc0201124:	4d1000ef          	jal	ffffffffc0201df4 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201128:	4509                	li	a0,2
ffffffffc020112a:	491000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc020112e:	34aa1563          	bne	s4,a0,ffffffffc0201478 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc0201132:	4589                	li	a1,2
ffffffffc0201134:	4c1000ef          	jal	ffffffffc0201df4 <free_pages>
    free_page(p2);
ffffffffc0201138:	04098513          	addi	a0,s3,64
ffffffffc020113c:	85d6                	mv	a1,s5
ffffffffc020113e:	4b7000ef          	jal	ffffffffc0201df4 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201142:	4515                	li	a0,5
ffffffffc0201144:	477000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0201148:	89aa                	mv	s3,a0
ffffffffc020114a:	48050763          	beqz	a0,ffffffffc02015d8 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc020114e:	8556                	mv	a0,s5
ffffffffc0201150:	46b000ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0201154:	2e051263          	bnez	a0,ffffffffc0201438 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc0201158:	000b0797          	auipc	a5,0xb0
ffffffffc020115c:	4a07a783          	lw	a5,1184(a5) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc0201160:	2a079c63          	bnez	a5,ffffffffc0201418 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201164:	854e                	mv	a0,s3
ffffffffc0201166:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0201168:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc020116c:	01793023          	sd	s7,0(s2)
ffffffffc0201170:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201174:	481000ef          	jal	ffffffffc0201df4 <free_pages>
    return listelm->next;
ffffffffc0201178:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020117c:	01278963          	beq	a5,s2,ffffffffc020118e <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201180:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201184:	679c                	ld	a5,8(a5)
ffffffffc0201186:	34fd                	addiw	s1,s1,-1
ffffffffc0201188:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020118a:	ff279be3          	bne	a5,s2,ffffffffc0201180 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc020118e:	26049563          	bnez	s1,ffffffffc02013f8 <default_check+0x552>
    assert(total == 0);
ffffffffc0201192:	46041363          	bnez	s0,ffffffffc02015f8 <default_check+0x752>
}
ffffffffc0201196:	60e6                	ld	ra,88(sp)
ffffffffc0201198:	6446                	ld	s0,80(sp)
ffffffffc020119a:	64a6                	ld	s1,72(sp)
ffffffffc020119c:	6906                	ld	s2,64(sp)
ffffffffc020119e:	79e2                	ld	s3,56(sp)
ffffffffc02011a0:	7a42                	ld	s4,48(sp)
ffffffffc02011a2:	7aa2                	ld	s5,40(sp)
ffffffffc02011a4:	7b02                	ld	s6,32(sp)
ffffffffc02011a6:	6be2                	ld	s7,24(sp)
ffffffffc02011a8:	6c42                	ld	s8,16(sp)
ffffffffc02011aa:	6ca2                	ld	s9,8(sp)
ffffffffc02011ac:	6125                	addi	sp,sp,96
ffffffffc02011ae:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02011b0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02011b2:	4401                	li	s0,0
ffffffffc02011b4:	4481                	li	s1,0
ffffffffc02011b6:	bb1d                	j	ffffffffc0200eec <default_check+0x46>
        assert(PageProperty(p));
ffffffffc02011b8:	00005697          	auipc	a3,0x5
ffffffffc02011bc:	0e868693          	addi	a3,a3,232 # ffffffffc02062a0 <etext+0x9fc>
ffffffffc02011c0:	00005617          	auipc	a2,0x5
ffffffffc02011c4:	0f060613          	addi	a2,a2,240 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02011c8:	11000593          	li	a1,272
ffffffffc02011cc:	00005517          	auipc	a0,0x5
ffffffffc02011d0:	0fc50513          	addi	a0,a0,252 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02011d4:	a76ff0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011d8:	00005697          	auipc	a3,0x5
ffffffffc02011dc:	1b068693          	addi	a3,a3,432 # ffffffffc0206388 <etext+0xae4>
ffffffffc02011e0:	00005617          	auipc	a2,0x5
ffffffffc02011e4:	0d060613          	addi	a2,a2,208 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02011e8:	0dc00593          	li	a1,220
ffffffffc02011ec:	00005517          	auipc	a0,0x5
ffffffffc02011f0:	0dc50513          	addi	a0,a0,220 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02011f4:	a56ff0ef          	jal	ffffffffc020044a <__panic>
    assert(!list_empty(&free_list));
ffffffffc02011f8:	00005697          	auipc	a3,0x5
ffffffffc02011fc:	25868693          	addi	a3,a3,600 # ffffffffc0206450 <etext+0xbac>
ffffffffc0201200:	00005617          	auipc	a2,0x5
ffffffffc0201204:	0b060613          	addi	a2,a2,176 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201208:	0f700593          	li	a1,247
ffffffffc020120c:	00005517          	auipc	a0,0x5
ffffffffc0201210:	0bc50513          	addi	a0,a0,188 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201214:	a36ff0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201218:	00005697          	auipc	a3,0x5
ffffffffc020121c:	1b068693          	addi	a3,a3,432 # ffffffffc02063c8 <etext+0xb24>
ffffffffc0201220:	00005617          	auipc	a2,0x5
ffffffffc0201224:	09060613          	addi	a2,a2,144 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201228:	0de00593          	li	a1,222
ffffffffc020122c:	00005517          	auipc	a0,0x5
ffffffffc0201230:	09c50513          	addi	a0,a0,156 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201234:	a16ff0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201238:	00005697          	auipc	a3,0x5
ffffffffc020123c:	12868693          	addi	a3,a3,296 # ffffffffc0206360 <etext+0xabc>
ffffffffc0201240:	00005617          	auipc	a2,0x5
ffffffffc0201244:	07060613          	addi	a2,a2,112 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201248:	0db00593          	li	a1,219
ffffffffc020124c:	00005517          	auipc	a0,0x5
ffffffffc0201250:	07c50513          	addi	a0,a0,124 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201254:	9f6ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201258:	00005697          	auipc	a3,0x5
ffffffffc020125c:	0a868693          	addi	a3,a3,168 # ffffffffc0206300 <etext+0xa5c>
ffffffffc0201260:	00005617          	auipc	a2,0x5
ffffffffc0201264:	05060613          	addi	a2,a2,80 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201268:	0f000593          	li	a1,240
ffffffffc020126c:	00005517          	auipc	a0,0x5
ffffffffc0201270:	05c50513          	addi	a0,a0,92 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201274:	9d6ff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 3);
ffffffffc0201278:	00005697          	auipc	a3,0x5
ffffffffc020127c:	1c868693          	addi	a3,a3,456 # ffffffffc0206440 <etext+0xb9c>
ffffffffc0201280:	00005617          	auipc	a2,0x5
ffffffffc0201284:	03060613          	addi	a2,a2,48 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201288:	0ee00593          	li	a1,238
ffffffffc020128c:	00005517          	auipc	a0,0x5
ffffffffc0201290:	03c50513          	addi	a0,a0,60 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201294:	9b6ff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201298:	00005697          	auipc	a3,0x5
ffffffffc020129c:	19068693          	addi	a3,a3,400 # ffffffffc0206428 <etext+0xb84>
ffffffffc02012a0:	00005617          	auipc	a2,0x5
ffffffffc02012a4:	01060613          	addi	a2,a2,16 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02012a8:	0e900593          	li	a1,233
ffffffffc02012ac:	00005517          	auipc	a0,0x5
ffffffffc02012b0:	01c50513          	addi	a0,a0,28 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02012b4:	996ff0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012b8:	00005697          	auipc	a3,0x5
ffffffffc02012bc:	15068693          	addi	a3,a3,336 # ffffffffc0206408 <etext+0xb64>
ffffffffc02012c0:	00005617          	auipc	a2,0x5
ffffffffc02012c4:	ff060613          	addi	a2,a2,-16 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02012c8:	0e000593          	li	a1,224
ffffffffc02012cc:	00005517          	auipc	a0,0x5
ffffffffc02012d0:	ffc50513          	addi	a0,a0,-4 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02012d4:	976ff0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 != NULL);
ffffffffc02012d8:	00005697          	auipc	a3,0x5
ffffffffc02012dc:	1c068693          	addi	a3,a3,448 # ffffffffc0206498 <etext+0xbf4>
ffffffffc02012e0:	00005617          	auipc	a2,0x5
ffffffffc02012e4:	fd060613          	addi	a2,a2,-48 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02012e8:	11800593          	li	a1,280
ffffffffc02012ec:	00005517          	auipc	a0,0x5
ffffffffc02012f0:	fdc50513          	addi	a0,a0,-36 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02012f4:	956ff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 0);
ffffffffc02012f8:	00005697          	auipc	a3,0x5
ffffffffc02012fc:	19068693          	addi	a3,a3,400 # ffffffffc0206488 <etext+0xbe4>
ffffffffc0201300:	00005617          	auipc	a2,0x5
ffffffffc0201304:	fb060613          	addi	a2,a2,-80 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201308:	0fd00593          	li	a1,253
ffffffffc020130c:	00005517          	auipc	a0,0x5
ffffffffc0201310:	fbc50513          	addi	a0,a0,-68 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201314:	936ff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201318:	00005697          	auipc	a3,0x5
ffffffffc020131c:	11068693          	addi	a3,a3,272 # ffffffffc0206428 <etext+0xb84>
ffffffffc0201320:	00005617          	auipc	a2,0x5
ffffffffc0201324:	f9060613          	addi	a2,a2,-112 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201328:	0fb00593          	li	a1,251
ffffffffc020132c:	00005517          	auipc	a0,0x5
ffffffffc0201330:	f9c50513          	addi	a0,a0,-100 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201334:	916ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201338:	00005697          	auipc	a3,0x5
ffffffffc020133c:	13068693          	addi	a3,a3,304 # ffffffffc0206468 <etext+0xbc4>
ffffffffc0201340:	00005617          	auipc	a2,0x5
ffffffffc0201344:	f7060613          	addi	a2,a2,-144 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201348:	0fa00593          	li	a1,250
ffffffffc020134c:	00005517          	auipc	a0,0x5
ffffffffc0201350:	f7c50513          	addi	a0,a0,-132 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201354:	8f6ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201358:	00005697          	auipc	a3,0x5
ffffffffc020135c:	fa868693          	addi	a3,a3,-88 # ffffffffc0206300 <etext+0xa5c>
ffffffffc0201360:	00005617          	auipc	a2,0x5
ffffffffc0201364:	f5060613          	addi	a2,a2,-176 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201368:	0d700593          	li	a1,215
ffffffffc020136c:	00005517          	auipc	a0,0x5
ffffffffc0201370:	f5c50513          	addi	a0,a0,-164 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201374:	8d6ff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201378:	00005697          	auipc	a3,0x5
ffffffffc020137c:	0b068693          	addi	a3,a3,176 # ffffffffc0206428 <etext+0xb84>
ffffffffc0201380:	00005617          	auipc	a2,0x5
ffffffffc0201384:	f3060613          	addi	a2,a2,-208 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201388:	0f400593          	li	a1,244
ffffffffc020138c:	00005517          	auipc	a0,0x5
ffffffffc0201390:	f3c50513          	addi	a0,a0,-196 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201394:	8b6ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201398:	00005697          	auipc	a3,0x5
ffffffffc020139c:	fa868693          	addi	a3,a3,-88 # ffffffffc0206340 <etext+0xa9c>
ffffffffc02013a0:	00005617          	auipc	a2,0x5
ffffffffc02013a4:	f1060613          	addi	a2,a2,-240 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02013a8:	0f200593          	li	a1,242
ffffffffc02013ac:	00005517          	auipc	a0,0x5
ffffffffc02013b0:	f1c50513          	addi	a0,a0,-228 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02013b4:	896ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013b8:	00005697          	auipc	a3,0x5
ffffffffc02013bc:	f6868693          	addi	a3,a3,-152 # ffffffffc0206320 <etext+0xa7c>
ffffffffc02013c0:	00005617          	auipc	a2,0x5
ffffffffc02013c4:	ef060613          	addi	a2,a2,-272 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02013c8:	0f100593          	li	a1,241
ffffffffc02013cc:	00005517          	auipc	a0,0x5
ffffffffc02013d0:	efc50513          	addi	a0,a0,-260 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02013d4:	876ff0ef          	jal	ffffffffc020044a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013d8:	00005697          	auipc	a3,0x5
ffffffffc02013dc:	f6868693          	addi	a3,a3,-152 # ffffffffc0206340 <etext+0xa9c>
ffffffffc02013e0:	00005617          	auipc	a2,0x5
ffffffffc02013e4:	ed060613          	addi	a2,a2,-304 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02013e8:	0d900593          	li	a1,217
ffffffffc02013ec:	00005517          	auipc	a0,0x5
ffffffffc02013f0:	edc50513          	addi	a0,a0,-292 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02013f4:	856ff0ef          	jal	ffffffffc020044a <__panic>
    assert(count == 0);
ffffffffc02013f8:	00005697          	auipc	a3,0x5
ffffffffc02013fc:	1f068693          	addi	a3,a3,496 # ffffffffc02065e8 <etext+0xd44>
ffffffffc0201400:	00005617          	auipc	a2,0x5
ffffffffc0201404:	eb060613          	addi	a2,a2,-336 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201408:	14600593          	li	a1,326
ffffffffc020140c:	00005517          	auipc	a0,0x5
ffffffffc0201410:	ebc50513          	addi	a0,a0,-324 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201414:	836ff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 0);
ffffffffc0201418:	00005697          	auipc	a3,0x5
ffffffffc020141c:	07068693          	addi	a3,a3,112 # ffffffffc0206488 <etext+0xbe4>
ffffffffc0201420:	00005617          	auipc	a2,0x5
ffffffffc0201424:	e9060613          	addi	a2,a2,-368 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201428:	13a00593          	li	a1,314
ffffffffc020142c:	00005517          	auipc	a0,0x5
ffffffffc0201430:	e9c50513          	addi	a0,a0,-356 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201434:	816ff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201438:	00005697          	auipc	a3,0x5
ffffffffc020143c:	ff068693          	addi	a3,a3,-16 # ffffffffc0206428 <etext+0xb84>
ffffffffc0201440:	00005617          	auipc	a2,0x5
ffffffffc0201444:	e7060613          	addi	a2,a2,-400 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201448:	13800593          	li	a1,312
ffffffffc020144c:	00005517          	auipc	a0,0x5
ffffffffc0201450:	e7c50513          	addi	a0,a0,-388 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201454:	ff7fe0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201458:	00005697          	auipc	a3,0x5
ffffffffc020145c:	f9068693          	addi	a3,a3,-112 # ffffffffc02063e8 <etext+0xb44>
ffffffffc0201460:	00005617          	auipc	a2,0x5
ffffffffc0201464:	e5060613          	addi	a2,a2,-432 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201468:	0df00593          	li	a1,223
ffffffffc020146c:	00005517          	auipc	a0,0x5
ffffffffc0201470:	e5c50513          	addi	a0,a0,-420 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201474:	fd7fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201478:	00005697          	auipc	a3,0x5
ffffffffc020147c:	13068693          	addi	a3,a3,304 # ffffffffc02065a8 <etext+0xd04>
ffffffffc0201480:	00005617          	auipc	a2,0x5
ffffffffc0201484:	e3060613          	addi	a2,a2,-464 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201488:	13200593          	li	a1,306
ffffffffc020148c:	00005517          	auipc	a0,0x5
ffffffffc0201490:	e3c50513          	addi	a0,a0,-452 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201494:	fb7fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201498:	00005697          	auipc	a3,0x5
ffffffffc020149c:	0f068693          	addi	a3,a3,240 # ffffffffc0206588 <etext+0xce4>
ffffffffc02014a0:	00005617          	auipc	a2,0x5
ffffffffc02014a4:	e1060613          	addi	a2,a2,-496 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02014a8:	13000593          	li	a1,304
ffffffffc02014ac:	00005517          	auipc	a0,0x5
ffffffffc02014b0:	e1c50513          	addi	a0,a0,-484 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02014b4:	f97fe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014b8:	00005697          	auipc	a3,0x5
ffffffffc02014bc:	0a868693          	addi	a3,a3,168 # ffffffffc0206560 <etext+0xcbc>
ffffffffc02014c0:	00005617          	auipc	a2,0x5
ffffffffc02014c4:	df060613          	addi	a2,a2,-528 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02014c8:	12e00593          	li	a1,302
ffffffffc02014cc:	00005517          	auipc	a0,0x5
ffffffffc02014d0:	dfc50513          	addi	a0,a0,-516 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02014d4:	f77fe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014d8:	00005697          	auipc	a3,0x5
ffffffffc02014dc:	06068693          	addi	a3,a3,96 # ffffffffc0206538 <etext+0xc94>
ffffffffc02014e0:	00005617          	auipc	a2,0x5
ffffffffc02014e4:	dd060613          	addi	a2,a2,-560 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02014e8:	12d00593          	li	a1,301
ffffffffc02014ec:	00005517          	auipc	a0,0x5
ffffffffc02014f0:	ddc50513          	addi	a0,a0,-548 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02014f4:	f57fe0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014f8:	00005697          	auipc	a3,0x5
ffffffffc02014fc:	03068693          	addi	a3,a3,48 # ffffffffc0206528 <etext+0xc84>
ffffffffc0201500:	00005617          	auipc	a2,0x5
ffffffffc0201504:	db060613          	addi	a2,a2,-592 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201508:	12800593          	li	a1,296
ffffffffc020150c:	00005517          	auipc	a0,0x5
ffffffffc0201510:	dbc50513          	addi	a0,a0,-580 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201514:	f37fe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201518:	00005697          	auipc	a3,0x5
ffffffffc020151c:	f1068693          	addi	a3,a3,-240 # ffffffffc0206428 <etext+0xb84>
ffffffffc0201520:	00005617          	auipc	a2,0x5
ffffffffc0201524:	d9060613          	addi	a2,a2,-624 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201528:	12700593          	li	a1,295
ffffffffc020152c:	00005517          	auipc	a0,0x5
ffffffffc0201530:	d9c50513          	addi	a0,a0,-612 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201534:	f17fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201538:	00005697          	auipc	a3,0x5
ffffffffc020153c:	fd068693          	addi	a3,a3,-48 # ffffffffc0206508 <etext+0xc64>
ffffffffc0201540:	00005617          	auipc	a2,0x5
ffffffffc0201544:	d7060613          	addi	a2,a2,-656 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201548:	12600593          	li	a1,294
ffffffffc020154c:	00005517          	auipc	a0,0x5
ffffffffc0201550:	d7c50513          	addi	a0,a0,-644 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201554:	ef7fe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201558:	00005697          	auipc	a3,0x5
ffffffffc020155c:	f8068693          	addi	a3,a3,-128 # ffffffffc02064d8 <etext+0xc34>
ffffffffc0201560:	00005617          	auipc	a2,0x5
ffffffffc0201564:	d5060613          	addi	a2,a2,-688 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201568:	12500593          	li	a1,293
ffffffffc020156c:	00005517          	auipc	a0,0x5
ffffffffc0201570:	d5c50513          	addi	a0,a0,-676 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201574:	ed7fe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201578:	00005697          	auipc	a3,0x5
ffffffffc020157c:	f4868693          	addi	a3,a3,-184 # ffffffffc02064c0 <etext+0xc1c>
ffffffffc0201580:	00005617          	auipc	a2,0x5
ffffffffc0201584:	d3060613          	addi	a2,a2,-720 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201588:	12400593          	li	a1,292
ffffffffc020158c:	00005517          	auipc	a0,0x5
ffffffffc0201590:	d3c50513          	addi	a0,a0,-708 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201594:	eb7fe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201598:	00005697          	auipc	a3,0x5
ffffffffc020159c:	e9068693          	addi	a3,a3,-368 # ffffffffc0206428 <etext+0xb84>
ffffffffc02015a0:	00005617          	auipc	a2,0x5
ffffffffc02015a4:	d1060613          	addi	a2,a2,-752 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02015a8:	11e00593          	li	a1,286
ffffffffc02015ac:	00005517          	auipc	a0,0x5
ffffffffc02015b0:	d1c50513          	addi	a0,a0,-740 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02015b4:	e97fe0ef          	jal	ffffffffc020044a <__panic>
    assert(!PageProperty(p0));
ffffffffc02015b8:	00005697          	auipc	a3,0x5
ffffffffc02015bc:	ef068693          	addi	a3,a3,-272 # ffffffffc02064a8 <etext+0xc04>
ffffffffc02015c0:	00005617          	auipc	a2,0x5
ffffffffc02015c4:	cf060613          	addi	a2,a2,-784 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02015c8:	11900593          	li	a1,281
ffffffffc02015cc:	00005517          	auipc	a0,0x5
ffffffffc02015d0:	cfc50513          	addi	a0,a0,-772 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02015d4:	e77fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015d8:	00005697          	auipc	a3,0x5
ffffffffc02015dc:	ff068693          	addi	a3,a3,-16 # ffffffffc02065c8 <etext+0xd24>
ffffffffc02015e0:	00005617          	auipc	a2,0x5
ffffffffc02015e4:	cd060613          	addi	a2,a2,-816 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02015e8:	13700593          	li	a1,311
ffffffffc02015ec:	00005517          	auipc	a0,0x5
ffffffffc02015f0:	cdc50513          	addi	a0,a0,-804 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02015f4:	e57fe0ef          	jal	ffffffffc020044a <__panic>
    assert(total == 0);
ffffffffc02015f8:	00005697          	auipc	a3,0x5
ffffffffc02015fc:	00068693          	mv	a3,a3
ffffffffc0201600:	00005617          	auipc	a2,0x5
ffffffffc0201604:	cb060613          	addi	a2,a2,-848 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201608:	14700593          	li	a1,327
ffffffffc020160c:	00005517          	auipc	a0,0x5
ffffffffc0201610:	cbc50513          	addi	a0,a0,-836 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201614:	e37fe0ef          	jal	ffffffffc020044a <__panic>
    assert(total == nr_free_pages());
ffffffffc0201618:	00005697          	auipc	a3,0x5
ffffffffc020161c:	cc868693          	addi	a3,a3,-824 # ffffffffc02062e0 <etext+0xa3c>
ffffffffc0201620:	00005617          	auipc	a2,0x5
ffffffffc0201624:	c9060613          	addi	a2,a2,-880 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201628:	11300593          	li	a1,275
ffffffffc020162c:	00005517          	auipc	a0,0x5
ffffffffc0201630:	c9c50513          	addi	a0,a0,-868 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201634:	e17fe0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201638:	00005697          	auipc	a3,0x5
ffffffffc020163c:	ce868693          	addi	a3,a3,-792 # ffffffffc0206320 <etext+0xa7c>
ffffffffc0201640:	00005617          	auipc	a2,0x5
ffffffffc0201644:	c7060613          	addi	a2,a2,-912 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201648:	0d800593          	li	a1,216
ffffffffc020164c:	00005517          	auipc	a0,0x5
ffffffffc0201650:	c7c50513          	addi	a0,a0,-900 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201654:	df7fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201658 <default_free_pages>:
{
ffffffffc0201658:	1141                	addi	sp,sp,-16
ffffffffc020165a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020165c:	14058663          	beqz	a1,ffffffffc02017a8 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc0201660:	00659713          	slli	a4,a1,0x6
ffffffffc0201664:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201668:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc020166a:	c30d                	beqz	a4,ffffffffc020168c <default_free_pages+0x34>
ffffffffc020166c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020166e:	8b05                	andi	a4,a4,1
ffffffffc0201670:	10071c63          	bnez	a4,ffffffffc0201788 <default_free_pages+0x130>
ffffffffc0201674:	6798                	ld	a4,8(a5)
ffffffffc0201676:	8b09                	andi	a4,a4,2
ffffffffc0201678:	10071863          	bnez	a4,ffffffffc0201788 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc020167c:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201680:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201684:	04078793          	addi	a5,a5,64
ffffffffc0201688:	fed792e3          	bne	a5,a3,ffffffffc020166c <default_free_pages+0x14>
    base->property = n;
ffffffffc020168c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020168e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201692:	4789                	li	a5,2
ffffffffc0201694:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201698:	000b0717          	auipc	a4,0xb0
ffffffffc020169c:	f6072703          	lw	a4,-160(a4) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc02016a0:	000b0697          	auipc	a3,0xb0
ffffffffc02016a4:	f4868693          	addi	a3,a3,-184 # ffffffffc02b15e8 <free_area>
    return list->next == list;
ffffffffc02016a8:	669c                	ld	a5,8(a3)
ffffffffc02016aa:	9f2d                	addw	a4,a4,a1
ffffffffc02016ac:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02016ae:	0ad78163          	beq	a5,a3,ffffffffc0201750 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc02016b2:	fe878713          	addi	a4,a5,-24
ffffffffc02016b6:	4581                	li	a1,0
ffffffffc02016b8:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02016bc:	00e56a63          	bltu	a0,a4,ffffffffc02016d0 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02016c0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02016c2:	04d70c63          	beq	a4,a3,ffffffffc020171a <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc02016c6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02016c8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02016cc:	fee57ae3          	bgeu	a0,a4,ffffffffc02016c0 <default_free_pages+0x68>
ffffffffc02016d0:	c199                	beqz	a1,ffffffffc02016d6 <default_free_pages+0x7e>
ffffffffc02016d2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016d6:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016d8:	e390                	sd	a2,0(a5)
ffffffffc02016da:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc02016dc:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02016de:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc02016e0:	00d70d63          	beq	a4,a3,ffffffffc02016fa <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02016e4:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016e8:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02016ec:	02059813          	slli	a6,a1,0x20
ffffffffc02016f0:	01a85793          	srli	a5,a6,0x1a
ffffffffc02016f4:	97b2                	add	a5,a5,a2
ffffffffc02016f6:	02f50c63          	beq	a0,a5,ffffffffc020172e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02016fa:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02016fc:	00d78c63          	beq	a5,a3,ffffffffc0201714 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201700:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201702:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201706:	02061593          	slli	a1,a2,0x20
ffffffffc020170a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020170e:	972a                	add	a4,a4,a0
ffffffffc0201710:	04e68c63          	beq	a3,a4,ffffffffc0201768 <default_free_pages+0x110>
}
ffffffffc0201714:	60a2                	ld	ra,8(sp)
ffffffffc0201716:	0141                	addi	sp,sp,16
ffffffffc0201718:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020171a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020171c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020171e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201720:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201722:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201724:	02d70f63          	beq	a4,a3,ffffffffc0201762 <default_free_pages+0x10a>
ffffffffc0201728:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020172a:	87ba                	mv	a5,a4
ffffffffc020172c:	bf71                	j	ffffffffc02016c8 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020172e:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201730:	5875                	li	a6,-3
ffffffffc0201732:	9fad                	addw	a5,a5,a1
ffffffffc0201734:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201738:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020173c:	01853803          	ld	a6,24(a0)
ffffffffc0201740:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201742:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201744:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_matrix_out_size+0xfe4ac8>
    return listelm->next;
ffffffffc0201748:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020174a:	0105b023          	sd	a6,0(a1)
ffffffffc020174e:	b77d                	j	ffffffffc02016fc <default_free_pages+0xa4>
}
ffffffffc0201750:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201752:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201756:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201758:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020175a:	e398                	sd	a4,0(a5)
ffffffffc020175c:	e798                	sd	a4,8(a5)
}
ffffffffc020175e:	0141                	addi	sp,sp,16
ffffffffc0201760:	8082                	ret
ffffffffc0201762:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201764:	873e                	mv	a4,a5
ffffffffc0201766:	bfad                	j	ffffffffc02016e0 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc0201768:	ff87a703          	lw	a4,-8(a5)
ffffffffc020176c:	56f5                	li	a3,-3
ffffffffc020176e:	9f31                	addw	a4,a4,a2
ffffffffc0201770:	c918                	sw	a4,16(a0)
ffffffffc0201772:	ff078713          	addi	a4,a5,-16
ffffffffc0201776:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020177a:	6398                	ld	a4,0(a5)
ffffffffc020177c:	679c                	ld	a5,8(a5)
}
ffffffffc020177e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201780:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201782:	e398                	sd	a4,0(a5)
ffffffffc0201784:	0141                	addi	sp,sp,16
ffffffffc0201786:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201788:	00005697          	auipc	a3,0x5
ffffffffc020178c:	e8868693          	addi	a3,a3,-376 # ffffffffc0206610 <etext+0xd6c>
ffffffffc0201790:	00005617          	auipc	a2,0x5
ffffffffc0201794:	b2060613          	addi	a2,a2,-1248 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201798:	09400593          	li	a1,148
ffffffffc020179c:	00005517          	auipc	a0,0x5
ffffffffc02017a0:	b2c50513          	addi	a0,a0,-1236 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02017a4:	ca7fe0ef          	jal	ffffffffc020044a <__panic>
    assert(n > 0);
ffffffffc02017a8:	00005697          	auipc	a3,0x5
ffffffffc02017ac:	e6068693          	addi	a3,a3,-416 # ffffffffc0206608 <etext+0xd64>
ffffffffc02017b0:	00005617          	auipc	a2,0x5
ffffffffc02017b4:	b0060613          	addi	a2,a2,-1280 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02017b8:	09000593          	li	a1,144
ffffffffc02017bc:	00005517          	auipc	a0,0x5
ffffffffc02017c0:	b0c50513          	addi	a0,a0,-1268 # ffffffffc02062c8 <etext+0xa24>
ffffffffc02017c4:	c87fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02017c8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017c8:	c951                	beqz	a0,ffffffffc020185c <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc02017ca:	000b0597          	auipc	a1,0xb0
ffffffffc02017ce:	e2e5a583          	lw	a1,-466(a1) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc02017d2:	86aa                	mv	a3,a0
ffffffffc02017d4:	02059793          	slli	a5,a1,0x20
ffffffffc02017d8:	9381                	srli	a5,a5,0x20
ffffffffc02017da:	00a7ef63          	bltu	a5,a0,ffffffffc02017f8 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02017de:	000b0617          	auipc	a2,0xb0
ffffffffc02017e2:	e0a60613          	addi	a2,a2,-502 # ffffffffc02b15e8 <free_area>
ffffffffc02017e6:	87b2                	mv	a5,a2
ffffffffc02017e8:	a029                	j	ffffffffc02017f2 <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc02017ea:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02017ee:	00d77763          	bgeu	a4,a3,ffffffffc02017fc <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02017f2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02017f4:	fec79be3          	bne	a5,a2,ffffffffc02017ea <default_alloc_pages+0x22>
        return NULL;
ffffffffc02017f8:	4501                	li	a0,0
}
ffffffffc02017fa:	8082                	ret
        if (page->property > n)
ffffffffc02017fc:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc0201800:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201804:	6798                	ld	a4,8(a5)
ffffffffc0201806:	02089313          	slli	t1,a7,0x20
ffffffffc020180a:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc020180e:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201812:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc0201816:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc020181a:	0266fa63          	bgeu	a3,t1,ffffffffc020184e <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020181e:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc0201822:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc0201826:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201828:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020182c:	00870313          	addi	t1,a4,8
ffffffffc0201830:	4889                	li	a7,2
ffffffffc0201832:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201836:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020183a:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc020183e:	0068b023          	sd	t1,0(a7)
ffffffffc0201842:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc0201846:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc020184a:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc020184e:	9d95                	subw	a1,a1,a3
ffffffffc0201850:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201852:	5775                	li	a4,-3
ffffffffc0201854:	17c1                	addi	a5,a5,-16
ffffffffc0201856:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020185a:	8082                	ret
{
ffffffffc020185c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020185e:	00005697          	auipc	a3,0x5
ffffffffc0201862:	daa68693          	addi	a3,a3,-598 # ffffffffc0206608 <etext+0xd64>
ffffffffc0201866:	00005617          	auipc	a2,0x5
ffffffffc020186a:	a4a60613          	addi	a2,a2,-1462 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020186e:	06c00593          	li	a1,108
ffffffffc0201872:	00005517          	auipc	a0,0x5
ffffffffc0201876:	a5650513          	addi	a0,a0,-1450 # ffffffffc02062c8 <etext+0xa24>
{
ffffffffc020187a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020187c:	bcffe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201880 <default_init_memmap>:
{
ffffffffc0201880:	1141                	addi	sp,sp,-16
ffffffffc0201882:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201884:	c9e1                	beqz	a1,ffffffffc0201954 <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc0201886:	00659713          	slli	a4,a1,0x6
ffffffffc020188a:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020188e:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201890:	cf11                	beqz	a4,ffffffffc02018ac <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201892:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201894:	8b05                	andi	a4,a4,1
ffffffffc0201896:	cf59                	beqz	a4,ffffffffc0201934 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201898:	0007a823          	sw	zero,16(a5)
ffffffffc020189c:	0007b423          	sd	zero,8(a5)
ffffffffc02018a0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018a4:	04078793          	addi	a5,a5,64
ffffffffc02018a8:	fed795e3          	bne	a5,a3,ffffffffc0201892 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02018ac:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018ae:	4789                	li	a5,2
ffffffffc02018b0:	00850713          	addi	a4,a0,8
ffffffffc02018b4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018b8:	000b0717          	auipc	a4,0xb0
ffffffffc02018bc:	d4072703          	lw	a4,-704(a4) # ffffffffc02b15f8 <free_area+0x10>
ffffffffc02018c0:	000b0697          	auipc	a3,0xb0
ffffffffc02018c4:	d2868693          	addi	a3,a3,-728 # ffffffffc02b15e8 <free_area>
    return list->next == list;
ffffffffc02018c8:	669c                	ld	a5,8(a3)
ffffffffc02018ca:	9f2d                	addw	a4,a4,a1
ffffffffc02018cc:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02018ce:	04d78663          	beq	a5,a3,ffffffffc020191a <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc02018d2:	fe878713          	addi	a4,a5,-24
ffffffffc02018d6:	4581                	li	a1,0
ffffffffc02018d8:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02018dc:	00e56a63          	bltu	a0,a4,ffffffffc02018f0 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02018e0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02018e2:	02d70263          	beq	a4,a3,ffffffffc0201906 <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02018e6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02018e8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02018ec:	fee57ae3          	bgeu	a0,a4,ffffffffc02018e0 <default_init_memmap+0x60>
ffffffffc02018f0:	c199                	beqz	a1,ffffffffc02018f6 <default_init_memmap+0x76>
ffffffffc02018f2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018f6:	6398                	ld	a4,0(a5)
}
ffffffffc02018f8:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018fa:	e390                	sd	a2,0(a5)
ffffffffc02018fc:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02018fe:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201900:	f11c                	sd	a5,32(a0)
ffffffffc0201902:	0141                	addi	sp,sp,16
ffffffffc0201904:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201906:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201908:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020190a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020190c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020190e:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201910:	00d70e63          	beq	a4,a3,ffffffffc020192c <default_init_memmap+0xac>
ffffffffc0201914:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201916:	87ba                	mv	a5,a4
ffffffffc0201918:	bfc1                	j	ffffffffc02018e8 <default_init_memmap+0x68>
}
ffffffffc020191a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020191c:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201920:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201922:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201924:	e398                	sd	a4,0(a5)
ffffffffc0201926:	e798                	sd	a4,8(a5)
}
ffffffffc0201928:	0141                	addi	sp,sp,16
ffffffffc020192a:	8082                	ret
ffffffffc020192c:	60a2                	ld	ra,8(sp)
ffffffffc020192e:	e290                	sd	a2,0(a3)
ffffffffc0201930:	0141                	addi	sp,sp,16
ffffffffc0201932:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201934:	00005697          	auipc	a3,0x5
ffffffffc0201938:	d0468693          	addi	a3,a3,-764 # ffffffffc0206638 <etext+0xd94>
ffffffffc020193c:	00005617          	auipc	a2,0x5
ffffffffc0201940:	97460613          	addi	a2,a2,-1676 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201944:	04b00593          	li	a1,75
ffffffffc0201948:	00005517          	auipc	a0,0x5
ffffffffc020194c:	98050513          	addi	a0,a0,-1664 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201950:	afbfe0ef          	jal	ffffffffc020044a <__panic>
    assert(n > 0);
ffffffffc0201954:	00005697          	auipc	a3,0x5
ffffffffc0201958:	cb468693          	addi	a3,a3,-844 # ffffffffc0206608 <etext+0xd64>
ffffffffc020195c:	00005617          	auipc	a2,0x5
ffffffffc0201960:	95460613          	addi	a2,a2,-1708 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201964:	04700593          	li	a1,71
ffffffffc0201968:	00005517          	auipc	a0,0x5
ffffffffc020196c:	96050513          	addi	a0,a0,-1696 # ffffffffc02062c8 <etext+0xa24>
ffffffffc0201970:	adbfe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201974 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201974:	c531                	beqz	a0,ffffffffc02019c0 <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201976:	e9b9                	bnez	a1,ffffffffc02019cc <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201978:	100027f3          	csrr	a5,sstatus
ffffffffc020197c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020197e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201980:	efb1                	bnez	a5,ffffffffc02019dc <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201982:	000b0797          	auipc	a5,0xb0
ffffffffc0201986:	8567b783          	ld	a5,-1962(a5) # ffffffffc02b11d8 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020198a:	873e                	mv	a4,a5
ffffffffc020198c:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020198e:	02a77a63          	bgeu	a4,a0,ffffffffc02019c2 <slob_free+0x4e>
ffffffffc0201992:	00f56463          	bltu	a0,a5,ffffffffc020199a <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201996:	fef76ae3          	bltu	a4,a5,ffffffffc020198a <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc020199a:	4110                	lw	a2,0(a0)
ffffffffc020199c:	00461693          	slli	a3,a2,0x4
ffffffffc02019a0:	96aa                	add	a3,a3,a0
ffffffffc02019a2:	0ad78463          	beq	a5,a3,ffffffffc0201a4a <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02019a6:	4310                	lw	a2,0(a4)
ffffffffc02019a8:	e51c                	sd	a5,8(a0)
ffffffffc02019aa:	00461693          	slli	a3,a2,0x4
ffffffffc02019ae:	96ba                	add	a3,a3,a4
ffffffffc02019b0:	08d50163          	beq	a0,a3,ffffffffc0201a32 <slob_free+0xbe>
ffffffffc02019b4:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc02019b6:	000b0797          	auipc	a5,0xb0
ffffffffc02019ba:	82e7b123          	sd	a4,-2014(a5) # ffffffffc02b11d8 <slobfree>
    if (flag)
ffffffffc02019be:	e9a5                	bnez	a1,ffffffffc0201a2e <slob_free+0xba>
ffffffffc02019c0:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019c2:	fcf574e3          	bgeu	a0,a5,ffffffffc020198a <slob_free+0x16>
ffffffffc02019c6:	fcf762e3          	bltu	a4,a5,ffffffffc020198a <slob_free+0x16>
ffffffffc02019ca:	bfc1                	j	ffffffffc020199a <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc02019cc:	25bd                	addiw	a1,a1,15
ffffffffc02019ce:	8191                	srli	a1,a1,0x4
ffffffffc02019d0:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019d2:	100027f3          	csrr	a5,sstatus
ffffffffc02019d6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019d8:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019da:	d7c5                	beqz	a5,ffffffffc0201982 <slob_free+0xe>
{
ffffffffc02019dc:	1101                	addi	sp,sp,-32
ffffffffc02019de:	e42a                	sd	a0,8(sp)
ffffffffc02019e0:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02019e2:	f1dfe0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc02019e6:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019e8:	000af797          	auipc	a5,0xaf
ffffffffc02019ec:	7f07b783          	ld	a5,2032(a5) # ffffffffc02b11d8 <slobfree>
ffffffffc02019f0:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019f2:	873e                	mv	a4,a5
ffffffffc02019f4:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019f6:	06a77663          	bgeu	a4,a0,ffffffffc0201a62 <slob_free+0xee>
ffffffffc02019fa:	00f56463          	bltu	a0,a5,ffffffffc0201a02 <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019fe:	fef76ae3          	bltu	a4,a5,ffffffffc02019f2 <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201a02:	4110                	lw	a2,0(a0)
ffffffffc0201a04:	00461693          	slli	a3,a2,0x4
ffffffffc0201a08:	96aa                	add	a3,a3,a0
ffffffffc0201a0a:	06d78363          	beq	a5,a3,ffffffffc0201a70 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201a0e:	4310                	lw	a2,0(a4)
ffffffffc0201a10:	e51c                	sd	a5,8(a0)
ffffffffc0201a12:	00461693          	slli	a3,a2,0x4
ffffffffc0201a16:	96ba                	add	a3,a3,a4
ffffffffc0201a18:	06d50163          	beq	a0,a3,ffffffffc0201a7a <slob_free+0x106>
ffffffffc0201a1c:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201a1e:	000af797          	auipc	a5,0xaf
ffffffffc0201a22:	7ae7bd23          	sd	a4,1978(a5) # ffffffffc02b11d8 <slobfree>
    if (flag)
ffffffffc0201a26:	e1a9                	bnez	a1,ffffffffc0201a68 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a28:	60e2                	ld	ra,24(sp)
ffffffffc0201a2a:	6105                	addi	sp,sp,32
ffffffffc0201a2c:	8082                	ret
        intr_enable();
ffffffffc0201a2e:	ecbfe06f          	j	ffffffffc02008f8 <intr_enable>
		cur->units += b->units;
ffffffffc0201a32:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201a34:	853e                	mv	a0,a5
ffffffffc0201a36:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201a38:	00c687bb          	addw	a5,a3,a2
ffffffffc0201a3c:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201a3e:	000af797          	auipc	a5,0xaf
ffffffffc0201a42:	78e7bd23          	sd	a4,1946(a5) # ffffffffc02b11d8 <slobfree>
    if (flag)
ffffffffc0201a46:	ddad                	beqz	a1,ffffffffc02019c0 <slob_free+0x4c>
ffffffffc0201a48:	b7dd                	j	ffffffffc0201a2e <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201a4a:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a4c:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201a4e:	9eb1                	addw	a3,a3,a2
ffffffffc0201a50:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201a52:	4310                	lw	a2,0(a4)
ffffffffc0201a54:	e51c                	sd	a5,8(a0)
ffffffffc0201a56:	00461693          	slli	a3,a2,0x4
ffffffffc0201a5a:	96ba                	add	a3,a3,a4
ffffffffc0201a5c:	f4d51ce3          	bne	a0,a3,ffffffffc02019b4 <slob_free+0x40>
ffffffffc0201a60:	bfc9                	j	ffffffffc0201a32 <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a62:	f8f56ee3          	bltu	a0,a5,ffffffffc02019fe <slob_free+0x8a>
ffffffffc0201a66:	b771                	j	ffffffffc02019f2 <slob_free+0x7e>
}
ffffffffc0201a68:	60e2                	ld	ra,24(sp)
ffffffffc0201a6a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201a6c:	e8dfe06f          	j	ffffffffc02008f8 <intr_enable>
		b->units += cur->next->units;
ffffffffc0201a70:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a72:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201a74:	9eb1                	addw	a3,a3,a2
ffffffffc0201a76:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201a78:	bf59                	j	ffffffffc0201a0e <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201a7a:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201a7c:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201a7e:	00c687bb          	addw	a5,a3,a2
ffffffffc0201a82:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201a84:	bf61                	j	ffffffffc0201a1c <slob_free+0xa8>

ffffffffc0201a86 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a86:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a88:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a8a:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a8e:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a90:	32a000ef          	jal	ffffffffc0201dba <alloc_pages>
	if (!page)
ffffffffc0201a94:	c91d                	beqz	a0,ffffffffc0201aca <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201a96:	000b4697          	auipc	a3,0xb4
ffffffffc0201a9a:	bfa6b683          	ld	a3,-1030(a3) # ffffffffc02b5690 <pages>
ffffffffc0201a9e:	00006797          	auipc	a5,0x6
ffffffffc0201aa2:	6a27b783          	ld	a5,1698(a5) # ffffffffc0208140 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201aa6:	000b4717          	auipc	a4,0xb4
ffffffffc0201aaa:	be273703          	ld	a4,-1054(a4) # ffffffffc02b5688 <npage>
    return page - pages + nbase;
ffffffffc0201aae:	8d15                	sub	a0,a0,a3
ffffffffc0201ab0:	8519                	srai	a0,a0,0x6
ffffffffc0201ab2:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201ab4:	00c51793          	slli	a5,a0,0xc
ffffffffc0201ab8:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201aba:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201abc:	00e7fa63          	bgeu	a5,a4,ffffffffc0201ad0 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201ac0:	000b4797          	auipc	a5,0xb4
ffffffffc0201ac4:	bc07b783          	ld	a5,-1088(a5) # ffffffffc02b5680 <va_pa_offset>
ffffffffc0201ac8:	953e                	add	a0,a0,a5
}
ffffffffc0201aca:	60a2                	ld	ra,8(sp)
ffffffffc0201acc:	0141                	addi	sp,sp,16
ffffffffc0201ace:	8082                	ret
ffffffffc0201ad0:	86aa                	mv	a3,a0
ffffffffc0201ad2:	00005617          	auipc	a2,0x5
ffffffffc0201ad6:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0206660 <etext+0xdbc>
ffffffffc0201ada:	07100593          	li	a1,113
ffffffffc0201ade:	00005517          	auipc	a0,0x5
ffffffffc0201ae2:	baa50513          	addi	a0,a0,-1110 # ffffffffc0206688 <etext+0xde4>
ffffffffc0201ae6:	965fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201aea <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201aea:	7179                	addi	sp,sp,-48
ffffffffc0201aec:	f406                	sd	ra,40(sp)
ffffffffc0201aee:	f022                	sd	s0,32(sp)
ffffffffc0201af0:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201af2:	01050713          	addi	a4,a0,16
ffffffffc0201af6:	6785                	lui	a5,0x1
ffffffffc0201af8:	0af77e63          	bgeu	a4,a5,ffffffffc0201bb4 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201afc:	00f50413          	addi	s0,a0,15
ffffffffc0201b00:	8011                	srli	s0,s0,0x4
ffffffffc0201b02:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b04:	100025f3          	csrr	a1,sstatus
ffffffffc0201b08:	8989                	andi	a1,a1,2
ffffffffc0201b0a:	edd1                	bnez	a1,ffffffffc0201ba6 <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201b0c:	000af497          	auipc	s1,0xaf
ffffffffc0201b10:	6cc48493          	addi	s1,s1,1740 # ffffffffc02b11d8 <slobfree>
ffffffffc0201b14:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b16:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201b18:	4314                	lw	a3,0(a4)
ffffffffc0201b1a:	0886da63          	bge	a3,s0,ffffffffc0201bae <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201b1e:	00e60a63          	beq	a2,a4,ffffffffc0201b32 <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b22:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201b24:	4394                	lw	a3,0(a5)
ffffffffc0201b26:	0286d863          	bge	a3,s0,ffffffffc0201b56 <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201b2a:	6090                	ld	a2,0(s1)
ffffffffc0201b2c:	873e                	mv	a4,a5
ffffffffc0201b2e:	fee61ae3          	bne	a2,a4,ffffffffc0201b22 <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201b32:	e9b1                	bnez	a1,ffffffffc0201b86 <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b34:	4501                	li	a0,0
ffffffffc0201b36:	f51ff0ef          	jal	ffffffffc0201a86 <__slob_get_free_pages.constprop.0>
ffffffffc0201b3a:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201b3c:	c915                	beqz	a0,ffffffffc0201b70 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b3e:	6585                	lui	a1,0x1
ffffffffc0201b40:	e35ff0ef          	jal	ffffffffc0201974 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b44:	100025f3          	csrr	a1,sstatus
ffffffffc0201b48:	8989                	andi	a1,a1,2
ffffffffc0201b4a:	e98d                	bnez	a1,ffffffffc0201b7c <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201b4c:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b4e:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201b50:	4394                	lw	a3,0(a5)
ffffffffc0201b52:	fc86cce3          	blt	a3,s0,ffffffffc0201b2a <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201b56:	04d40563          	beq	s0,a3,ffffffffc0201ba0 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201b5a:	00441613          	slli	a2,s0,0x4
ffffffffc0201b5e:	963e                	add	a2,a2,a5
ffffffffc0201b60:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201b62:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201b64:	9e81                	subw	a3,a3,s0
ffffffffc0201b66:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201b68:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201b6a:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201b6c:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201b6e:	ed99                	bnez	a1,ffffffffc0201b8c <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201b70:	70a2                	ld	ra,40(sp)
ffffffffc0201b72:	7402                	ld	s0,32(sp)
ffffffffc0201b74:	64e2                	ld	s1,24(sp)
ffffffffc0201b76:	853e                	mv	a0,a5
ffffffffc0201b78:	6145                	addi	sp,sp,48
ffffffffc0201b7a:	8082                	ret
        intr_disable();
ffffffffc0201b7c:	d83fe0ef          	jal	ffffffffc02008fe <intr_disable>
			cur = slobfree;
ffffffffc0201b80:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201b82:	4585                	li	a1,1
ffffffffc0201b84:	b7e9                	j	ffffffffc0201b4e <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201b86:	d73fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201b8a:	b76d                	j	ffffffffc0201b34 <slob_alloc.constprop.0+0x4a>
ffffffffc0201b8c:	e43e                	sd	a5,8(sp)
ffffffffc0201b8e:	d6bfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201b92:	67a2                	ld	a5,8(sp)
}
ffffffffc0201b94:	70a2                	ld	ra,40(sp)
ffffffffc0201b96:	7402                	ld	s0,32(sp)
ffffffffc0201b98:	64e2                	ld	s1,24(sp)
ffffffffc0201b9a:	853e                	mv	a0,a5
ffffffffc0201b9c:	6145                	addi	sp,sp,48
ffffffffc0201b9e:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201ba0:	6794                	ld	a3,8(a5)
ffffffffc0201ba2:	e714                	sd	a3,8(a4)
ffffffffc0201ba4:	b7e1                	j	ffffffffc0201b6c <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201ba6:	d59fe0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0201baa:	4585                	li	a1,1
ffffffffc0201bac:	b785                	j	ffffffffc0201b0c <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bae:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201bb0:	8732                	mv	a4,a2
ffffffffc0201bb2:	b755                	j	ffffffffc0201b56 <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bb4:	00005697          	auipc	a3,0x5
ffffffffc0201bb8:	ae468693          	addi	a3,a3,-1308 # ffffffffc0206698 <etext+0xdf4>
ffffffffc0201bbc:	00004617          	auipc	a2,0x4
ffffffffc0201bc0:	6f460613          	addi	a2,a2,1780 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0201bc4:	06400593          	li	a1,100
ffffffffc0201bc8:	00005517          	auipc	a0,0x5
ffffffffc0201bcc:	af050513          	addi	a0,a0,-1296 # ffffffffc02066b8 <etext+0xe14>
ffffffffc0201bd0:	87bfe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201bd4 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201bd4:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201bd6:	00005517          	auipc	a0,0x5
ffffffffc0201bda:	afa50513          	addi	a0,a0,-1286 # ffffffffc02066d0 <etext+0xe2c>
{
ffffffffc0201bde:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201be0:	db8fe0ef          	jal	ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201be4:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201be6:	00005517          	auipc	a0,0x5
ffffffffc0201bea:	b0250513          	addi	a0,a0,-1278 # ffffffffc02066e8 <etext+0xe44>
}
ffffffffc0201bee:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201bf0:	da8fe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201bf4 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201bf4:	4501                	li	a0,0
ffffffffc0201bf6:	8082                	ret

ffffffffc0201bf8 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201bf8:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bfa:	6685                	lui	a3,0x1
{
ffffffffc0201bfc:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bfe:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7f39>
ffffffffc0201c00:	04a6f963          	bgeu	a3,a0,ffffffffc0201c52 <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c04:	e42a                	sd	a0,8(sp)
ffffffffc0201c06:	4561                	li	a0,24
ffffffffc0201c08:	e822                	sd	s0,16(sp)
ffffffffc0201c0a:	ee1ff0ef          	jal	ffffffffc0201aea <slob_alloc.constprop.0>
ffffffffc0201c0e:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201c10:	c541                	beqz	a0,ffffffffc0201c98 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201c12:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201c14:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201c16:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201c18:	00f75763          	bge	a4,a5,ffffffffc0201c26 <kmalloc+0x2e>
ffffffffc0201c1c:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201c20:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201c22:	fef74de3          	blt	a4,a5,ffffffffc0201c1c <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201c26:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c28:	e5fff0ef          	jal	ffffffffc0201a86 <__slob_get_free_pages.constprop.0>
ffffffffc0201c2c:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201c2e:	cd31                	beqz	a0,ffffffffc0201c8a <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c30:	100027f3          	csrr	a5,sstatus
ffffffffc0201c34:	8b89                	andi	a5,a5,2
ffffffffc0201c36:	eb85                	bnez	a5,ffffffffc0201c66 <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201c38:	000b4797          	auipc	a5,0xb4
ffffffffc0201c3c:	a287b783          	ld	a5,-1496(a5) # ffffffffc02b5660 <bigblocks>
		bigblocks = bb;
ffffffffc0201c40:	000b4717          	auipc	a4,0xb4
ffffffffc0201c44:	a2873023          	sd	s0,-1504(a4) # ffffffffc02b5660 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201c48:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201c4a:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201c4c:	60e2                	ld	ra,24(sp)
ffffffffc0201c4e:	6105                	addi	sp,sp,32
ffffffffc0201c50:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201c52:	0541                	addi	a0,a0,16
ffffffffc0201c54:	e97ff0ef          	jal	ffffffffc0201aea <slob_alloc.constprop.0>
ffffffffc0201c58:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201c5a:	0541                	addi	a0,a0,16
ffffffffc0201c5c:	fbe5                	bnez	a5,ffffffffc0201c4c <kmalloc+0x54>
		return 0;
ffffffffc0201c5e:	4501                	li	a0,0
}
ffffffffc0201c60:	60e2                	ld	ra,24(sp)
ffffffffc0201c62:	6105                	addi	sp,sp,32
ffffffffc0201c64:	8082                	ret
        intr_disable();
ffffffffc0201c66:	c99fe0ef          	jal	ffffffffc02008fe <intr_disable>
		bb->next = bigblocks;
ffffffffc0201c6a:	000b4797          	auipc	a5,0xb4
ffffffffc0201c6e:	9f67b783          	ld	a5,-1546(a5) # ffffffffc02b5660 <bigblocks>
		bigblocks = bb;
ffffffffc0201c72:	000b4717          	auipc	a4,0xb4
ffffffffc0201c76:	9e873723          	sd	s0,-1554(a4) # ffffffffc02b5660 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201c7a:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201c7c:	c7dfe0ef          	jal	ffffffffc02008f8 <intr_enable>
		return bb->pages;
ffffffffc0201c80:	6408                	ld	a0,8(s0)
}
ffffffffc0201c82:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201c84:	6442                	ld	s0,16(sp)
}
ffffffffc0201c86:	6105                	addi	sp,sp,32
ffffffffc0201c88:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c8a:	8522                	mv	a0,s0
ffffffffc0201c8c:	45e1                	li	a1,24
ffffffffc0201c8e:	ce7ff0ef          	jal	ffffffffc0201974 <slob_free>
		return 0;
ffffffffc0201c92:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c94:	6442                	ld	s0,16(sp)
ffffffffc0201c96:	b7e9                	j	ffffffffc0201c60 <kmalloc+0x68>
ffffffffc0201c98:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201c9a:	4501                	li	a0,0
ffffffffc0201c9c:	b7d1                	j	ffffffffc0201c60 <kmalloc+0x68>

ffffffffc0201c9e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201c9e:	c571                	beqz	a0,ffffffffc0201d6a <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201ca0:	03451793          	slli	a5,a0,0x34
ffffffffc0201ca4:	e3e1                	bnez	a5,ffffffffc0201d64 <kfree+0xc6>
{
ffffffffc0201ca6:	1101                	addi	sp,sp,-32
ffffffffc0201ca8:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201caa:	100027f3          	csrr	a5,sstatus
ffffffffc0201cae:	8b89                	andi	a5,a5,2
ffffffffc0201cb0:	e7c1                	bnez	a5,ffffffffc0201d38 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cb2:	000b4797          	auipc	a5,0xb4
ffffffffc0201cb6:	9ae7b783          	ld	a5,-1618(a5) # ffffffffc02b5660 <bigblocks>
    return 0;
ffffffffc0201cba:	4581                	li	a1,0
ffffffffc0201cbc:	cbad                	beqz	a5,ffffffffc0201d2e <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201cbe:	000b4617          	auipc	a2,0xb4
ffffffffc0201cc2:	9a260613          	addi	a2,a2,-1630 # ffffffffc02b5660 <bigblocks>
ffffffffc0201cc6:	a021                	j	ffffffffc0201cce <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cc8:	01070613          	addi	a2,a4,16
ffffffffc0201ccc:	c3a5                	beqz	a5,ffffffffc0201d2c <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201cce:	6794                	ld	a3,8(a5)
ffffffffc0201cd0:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201cd2:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201cd4:	fea69ae3          	bne	a3,a0,ffffffffc0201cc8 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201cd8:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201cda:	edb5                	bnez	a1,ffffffffc0201d56 <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201cdc:	c02007b7          	lui	a5,0xc0200
ffffffffc0201ce0:	0af56263          	bltu	a0,a5,ffffffffc0201d84 <kfree+0xe6>
ffffffffc0201ce4:	000b4797          	auipc	a5,0xb4
ffffffffc0201ce8:	99c7b783          	ld	a5,-1636(a5) # ffffffffc02b5680 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201cec:	000b4697          	auipc	a3,0xb4
ffffffffc0201cf0:	99c6b683          	ld	a3,-1636(a3) # ffffffffc02b5688 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201cf4:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201cf6:	00c55793          	srli	a5,a0,0xc
ffffffffc0201cfa:	06d7f963          	bgeu	a5,a3,ffffffffc0201d6c <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201cfe:	00006617          	auipc	a2,0x6
ffffffffc0201d02:	44263603          	ld	a2,1090(a2) # ffffffffc0208140 <nbase>
ffffffffc0201d06:	000b4517          	auipc	a0,0xb4
ffffffffc0201d0a:	98a53503          	ld	a0,-1654(a0) # ffffffffc02b5690 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201d0e:	4314                	lw	a3,0(a4)
ffffffffc0201d10:	8f91                	sub	a5,a5,a2
ffffffffc0201d12:	079a                	slli	a5,a5,0x6
ffffffffc0201d14:	4585                	li	a1,1
ffffffffc0201d16:	953e                	add	a0,a0,a5
ffffffffc0201d18:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201d1c:	e03a                	sd	a4,0(sp)
ffffffffc0201d1e:	0d6000ef          	jal	ffffffffc0201df4 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d22:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d24:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d26:	45e1                	li	a1,24
}
ffffffffc0201d28:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d2a:	b1a9                	j	ffffffffc0201974 <slob_free>
ffffffffc0201d2c:	e185                	bnez	a1,ffffffffc0201d4c <kfree+0xae>
}
ffffffffc0201d2e:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d30:	1541                	addi	a0,a0,-16
ffffffffc0201d32:	4581                	li	a1,0
}
ffffffffc0201d34:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d36:	b93d                	j	ffffffffc0201974 <slob_free>
        intr_disable();
ffffffffc0201d38:	e02a                	sd	a0,0(sp)
ffffffffc0201d3a:	bc5fe0ef          	jal	ffffffffc02008fe <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d3e:	000b4797          	auipc	a5,0xb4
ffffffffc0201d42:	9227b783          	ld	a5,-1758(a5) # ffffffffc02b5660 <bigblocks>
ffffffffc0201d46:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201d48:	4585                	li	a1,1
ffffffffc0201d4a:	fbb5                	bnez	a5,ffffffffc0201cbe <kfree+0x20>
ffffffffc0201d4c:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201d4e:	babfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201d52:	6502                	ld	a0,0(sp)
ffffffffc0201d54:	bfe9                	j	ffffffffc0201d2e <kfree+0x90>
ffffffffc0201d56:	e42a                	sd	a0,8(sp)
ffffffffc0201d58:	e03a                	sd	a4,0(sp)
ffffffffc0201d5a:	b9ffe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201d5e:	6522                	ld	a0,8(sp)
ffffffffc0201d60:	6702                	ld	a4,0(sp)
ffffffffc0201d62:	bfad                	j	ffffffffc0201cdc <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d64:	1541                	addi	a0,a0,-16
ffffffffc0201d66:	4581                	li	a1,0
ffffffffc0201d68:	b131                	j	ffffffffc0201974 <slob_free>
ffffffffc0201d6a:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201d6c:	00005617          	auipc	a2,0x5
ffffffffc0201d70:	9c460613          	addi	a2,a2,-1596 # ffffffffc0206730 <etext+0xe8c>
ffffffffc0201d74:	06900593          	li	a1,105
ffffffffc0201d78:	00005517          	auipc	a0,0x5
ffffffffc0201d7c:	91050513          	addi	a0,a0,-1776 # ffffffffc0206688 <etext+0xde4>
ffffffffc0201d80:	ecafe0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201d84:	86aa                	mv	a3,a0
ffffffffc0201d86:	00005617          	auipc	a2,0x5
ffffffffc0201d8a:	98260613          	addi	a2,a2,-1662 # ffffffffc0206708 <etext+0xe64>
ffffffffc0201d8e:	07700593          	li	a1,119
ffffffffc0201d92:	00005517          	auipc	a0,0x5
ffffffffc0201d96:	8f650513          	addi	a0,a0,-1802 # ffffffffc0206688 <etext+0xde4>
ffffffffc0201d9a:	eb0fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201d9e <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201d9e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201da0:	00005617          	auipc	a2,0x5
ffffffffc0201da4:	99060613          	addi	a2,a2,-1648 # ffffffffc0206730 <etext+0xe8c>
ffffffffc0201da8:	06900593          	li	a1,105
ffffffffc0201dac:	00005517          	auipc	a0,0x5
ffffffffc0201db0:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0206688 <etext+0xde4>
pa2page(uintptr_t pa)
ffffffffc0201db4:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201db6:	e94fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201dba <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dba:	100027f3          	csrr	a5,sstatus
ffffffffc0201dbe:	8b89                	andi	a5,a5,2
ffffffffc0201dc0:	e799                	bnez	a5,ffffffffc0201dce <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dc2:	000b4797          	auipc	a5,0xb4
ffffffffc0201dc6:	8a67b783          	ld	a5,-1882(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201dca:	6f9c                	ld	a5,24(a5)
ffffffffc0201dcc:	8782                	jr	a5
{
ffffffffc0201dce:	1101                	addi	sp,sp,-32
ffffffffc0201dd0:	ec06                	sd	ra,24(sp)
ffffffffc0201dd2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201dd4:	b2bfe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dd8:	000b4797          	auipc	a5,0xb4
ffffffffc0201ddc:	8907b783          	ld	a5,-1904(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201de0:	6522                	ld	a0,8(sp)
ffffffffc0201de2:	6f9c                	ld	a5,24(a5)
ffffffffc0201de4:	9782                	jalr	a5
ffffffffc0201de6:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201de8:	b11fe0ef          	jal	ffffffffc02008f8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201dec:	60e2                	ld	ra,24(sp)
ffffffffc0201dee:	6522                	ld	a0,8(sp)
ffffffffc0201df0:	6105                	addi	sp,sp,32
ffffffffc0201df2:	8082                	ret

ffffffffc0201df4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201df4:	100027f3          	csrr	a5,sstatus
ffffffffc0201df8:	8b89                	andi	a5,a5,2
ffffffffc0201dfa:	e799                	bnez	a5,ffffffffc0201e08 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201dfc:	000b4797          	auipc	a5,0xb4
ffffffffc0201e00:	86c7b783          	ld	a5,-1940(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201e04:	739c                	ld	a5,32(a5)
ffffffffc0201e06:	8782                	jr	a5
{
ffffffffc0201e08:	1101                	addi	sp,sp,-32
ffffffffc0201e0a:	ec06                	sd	ra,24(sp)
ffffffffc0201e0c:	e42e                	sd	a1,8(sp)
ffffffffc0201e0e:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201e10:	aeffe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201e14:	000b4797          	auipc	a5,0xb4
ffffffffc0201e18:	8547b783          	ld	a5,-1964(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201e1c:	65a2                	ld	a1,8(sp)
ffffffffc0201e1e:	6502                	ld	a0,0(sp)
ffffffffc0201e20:	739c                	ld	a5,32(a5)
ffffffffc0201e22:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201e24:	60e2                	ld	ra,24(sp)
ffffffffc0201e26:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201e28:	ad1fe06f          	j	ffffffffc02008f8 <intr_enable>

ffffffffc0201e2c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e2c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e30:	8b89                	andi	a5,a5,2
ffffffffc0201e32:	e799                	bnez	a5,ffffffffc0201e40 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e34:	000b4797          	auipc	a5,0xb4
ffffffffc0201e38:	8347b783          	ld	a5,-1996(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201e3c:	779c                	ld	a5,40(a5)
ffffffffc0201e3e:	8782                	jr	a5
{
ffffffffc0201e40:	1101                	addi	sp,sp,-32
ffffffffc0201e42:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201e44:	abbfe0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e48:	000b4797          	auipc	a5,0xb4
ffffffffc0201e4c:	8207b783          	ld	a5,-2016(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201e50:	779c                	ld	a5,40(a5)
ffffffffc0201e52:	9782                	jalr	a5
ffffffffc0201e54:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201e56:	aa3fe0ef          	jal	ffffffffc02008f8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201e5a:	60e2                	ld	ra,24(sp)
ffffffffc0201e5c:	6522                	ld	a0,8(sp)
ffffffffc0201e5e:	6105                	addi	sp,sp,32
ffffffffc0201e60:	8082                	ret

ffffffffc0201e62 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e62:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e66:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e6a:	078e                	slli	a5,a5,0x3
ffffffffc0201e6c:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201e70:	6314                	ld	a3,0(a4)
{
ffffffffc0201e72:	7139                	addi	sp,sp,-64
ffffffffc0201e74:	f822                	sd	s0,48(sp)
ffffffffc0201e76:	f426                	sd	s1,40(sp)
ffffffffc0201e78:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201e7a:	0016f793          	andi	a5,a3,1
{
ffffffffc0201e7e:	842e                	mv	s0,a1
ffffffffc0201e80:	8832                	mv	a6,a2
ffffffffc0201e82:	000b4497          	auipc	s1,0xb4
ffffffffc0201e86:	80648493          	addi	s1,s1,-2042 # ffffffffc02b5688 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201e8a:	ebd1                	bnez	a5,ffffffffc0201f1e <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e8c:	16060d63          	beqz	a2,ffffffffc0202006 <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e90:	100027f3          	csrr	a5,sstatus
ffffffffc0201e94:	8b89                	andi	a5,a5,2
ffffffffc0201e96:	16079e63          	bnez	a5,ffffffffc0202012 <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e9a:	000b3797          	auipc	a5,0xb3
ffffffffc0201e9e:	7ce7b783          	ld	a5,1998(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201ea2:	4505                	li	a0,1
ffffffffc0201ea4:	e43a                	sd	a4,8(sp)
ffffffffc0201ea6:	6f9c                	ld	a5,24(a5)
ffffffffc0201ea8:	e832                	sd	a2,16(sp)
ffffffffc0201eaa:	9782                	jalr	a5
ffffffffc0201eac:	6722                	ld	a4,8(sp)
ffffffffc0201eae:	6842                	ld	a6,16(sp)
ffffffffc0201eb0:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201eb2:	14078a63          	beqz	a5,ffffffffc0202006 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201eb6:	000b3517          	auipc	a0,0xb3
ffffffffc0201eba:	7da53503          	ld	a0,2010(a0) # ffffffffc02b5690 <pages>
ffffffffc0201ebe:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ec2:	000b3497          	auipc	s1,0xb3
ffffffffc0201ec6:	7c648493          	addi	s1,s1,1990 # ffffffffc02b5688 <npage>
ffffffffc0201eca:	40a78533          	sub	a0,a5,a0
ffffffffc0201ece:	8519                	srai	a0,a0,0x6
ffffffffc0201ed0:	9546                	add	a0,a0,a7
ffffffffc0201ed2:	6090                	ld	a2,0(s1)
ffffffffc0201ed4:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201ed8:	4585                	li	a1,1
ffffffffc0201eda:	82b1                	srli	a3,a3,0xc
ffffffffc0201edc:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ede:	0532                	slli	a0,a0,0xc
ffffffffc0201ee0:	1ac6f763          	bgeu	a3,a2,ffffffffc020208e <get_pte+0x22c>
ffffffffc0201ee4:	000b3697          	auipc	a3,0xb3
ffffffffc0201ee8:	79c6b683          	ld	a3,1948(a3) # ffffffffc02b5680 <va_pa_offset>
ffffffffc0201eec:	6605                	lui	a2,0x1
ffffffffc0201eee:	4581                	li	a1,0
ffffffffc0201ef0:	9536                	add	a0,a0,a3
ffffffffc0201ef2:	ec42                	sd	a6,24(sp)
ffffffffc0201ef4:	e83e                	sd	a5,16(sp)
ffffffffc0201ef6:	e43a                	sd	a4,8(sp)
ffffffffc0201ef8:	183030ef          	jal	ffffffffc020587a <memset>
    return page - pages + nbase;
ffffffffc0201efc:	000b3697          	auipc	a3,0xb3
ffffffffc0201f00:	7946b683          	ld	a3,1940(a3) # ffffffffc02b5690 <pages>
ffffffffc0201f04:	67c2                	ld	a5,16(sp)
ffffffffc0201f06:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f0a:	6722                	ld	a4,8(sp)
ffffffffc0201f0c:	40d786b3          	sub	a3,a5,a3
ffffffffc0201f10:	8699                	srai	a3,a3,0x6
ffffffffc0201f12:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f14:	06aa                	slli	a3,a3,0xa
ffffffffc0201f16:	6862                	ld	a6,24(sp)
ffffffffc0201f18:	0116e693          	ori	a3,a3,17
ffffffffc0201f1c:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f1e:	c006f693          	andi	a3,a3,-1024
ffffffffc0201f22:	6098                	ld	a4,0(s1)
ffffffffc0201f24:	068a                	slli	a3,a3,0x2
ffffffffc0201f26:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f2a:	14e7f663          	bgeu	a5,a4,ffffffffc0202076 <get_pte+0x214>
ffffffffc0201f2e:	000b3897          	auipc	a7,0xb3
ffffffffc0201f32:	75288893          	addi	a7,a7,1874 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0201f36:	0008b603          	ld	a2,0(a7)
ffffffffc0201f3a:	01545793          	srli	a5,s0,0x15
ffffffffc0201f3e:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f42:	96b2                	add	a3,a3,a2
ffffffffc0201f44:	078e                	slli	a5,a5,0x3
ffffffffc0201f46:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201f48:	6394                	ld	a3,0(a5)
ffffffffc0201f4a:	0016f613          	andi	a2,a3,1
ffffffffc0201f4e:	e659                	bnez	a2,ffffffffc0201fdc <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f50:	0a080b63          	beqz	a6,ffffffffc0202006 <get_pte+0x1a4>
ffffffffc0201f54:	10002773          	csrr	a4,sstatus
ffffffffc0201f58:	8b09                	andi	a4,a4,2
ffffffffc0201f5a:	ef71                	bnez	a4,ffffffffc0202036 <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f5c:	000b3717          	auipc	a4,0xb3
ffffffffc0201f60:	70c73703          	ld	a4,1804(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc0201f64:	4505                	li	a0,1
ffffffffc0201f66:	e43e                	sd	a5,8(sp)
ffffffffc0201f68:	6f18                	ld	a4,24(a4)
ffffffffc0201f6a:	9702                	jalr	a4
ffffffffc0201f6c:	67a2                	ld	a5,8(sp)
ffffffffc0201f6e:	872a                	mv	a4,a0
ffffffffc0201f70:	000b3897          	auipc	a7,0xb3
ffffffffc0201f74:	71088893          	addi	a7,a7,1808 # ffffffffc02b5680 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f78:	c759                	beqz	a4,ffffffffc0202006 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201f7a:	000b3697          	auipc	a3,0xb3
ffffffffc0201f7e:	7166b683          	ld	a3,1814(a3) # ffffffffc02b5690 <pages>
ffffffffc0201f82:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f86:	608c                	ld	a1,0(s1)
ffffffffc0201f88:	40d706b3          	sub	a3,a4,a3
ffffffffc0201f8c:	8699                	srai	a3,a3,0x6
ffffffffc0201f8e:	96c2                	add	a3,a3,a6
ffffffffc0201f90:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0201f94:	4505                	li	a0,1
ffffffffc0201f96:	8231                	srli	a2,a2,0xc
ffffffffc0201f98:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f9a:	06b2                	slli	a3,a3,0xc
ffffffffc0201f9c:	10b67663          	bgeu	a2,a1,ffffffffc02020a8 <get_pte+0x246>
ffffffffc0201fa0:	0008b503          	ld	a0,0(a7)
ffffffffc0201fa4:	6605                	lui	a2,0x1
ffffffffc0201fa6:	4581                	li	a1,0
ffffffffc0201fa8:	9536                	add	a0,a0,a3
ffffffffc0201faa:	e83a                	sd	a4,16(sp)
ffffffffc0201fac:	e43e                	sd	a5,8(sp)
ffffffffc0201fae:	0cd030ef          	jal	ffffffffc020587a <memset>
    return page - pages + nbase;
ffffffffc0201fb2:	000b3697          	auipc	a3,0xb3
ffffffffc0201fb6:	6de6b683          	ld	a3,1758(a3) # ffffffffc02b5690 <pages>
ffffffffc0201fba:	6742                	ld	a4,16(sp)
ffffffffc0201fbc:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fc0:	67a2                	ld	a5,8(sp)
ffffffffc0201fc2:	40d706b3          	sub	a3,a4,a3
ffffffffc0201fc6:	8699                	srai	a3,a3,0x6
ffffffffc0201fc8:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fca:	06aa                	slli	a3,a3,0xa
ffffffffc0201fcc:	0116e693          	ori	a3,a3,17
ffffffffc0201fd0:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201fd2:	6098                	ld	a4,0(s1)
ffffffffc0201fd4:	000b3897          	auipc	a7,0xb3
ffffffffc0201fd8:	6ac88893          	addi	a7,a7,1708 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0201fdc:	c006f693          	andi	a3,a3,-1024
ffffffffc0201fe0:	068a                	slli	a3,a3,0x2
ffffffffc0201fe2:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fe6:	06e7fc63          	bgeu	a5,a4,ffffffffc020205e <get_pte+0x1fc>
ffffffffc0201fea:	0008b783          	ld	a5,0(a7)
ffffffffc0201fee:	8031                	srli	s0,s0,0xc
ffffffffc0201ff0:	1ff47413          	andi	s0,s0,511
ffffffffc0201ff4:	040e                	slli	s0,s0,0x3
ffffffffc0201ff6:	96be                	add	a3,a3,a5
}
ffffffffc0201ff8:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ffa:	00868533          	add	a0,a3,s0
}
ffffffffc0201ffe:	7442                	ld	s0,48(sp)
ffffffffc0202000:	74a2                	ld	s1,40(sp)
ffffffffc0202002:	6121                	addi	sp,sp,64
ffffffffc0202004:	8082                	ret
ffffffffc0202006:	70e2                	ld	ra,56(sp)
ffffffffc0202008:	7442                	ld	s0,48(sp)
ffffffffc020200a:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc020200c:	4501                	li	a0,0
}
ffffffffc020200e:	6121                	addi	sp,sp,64
ffffffffc0202010:	8082                	ret
        intr_disable();
ffffffffc0202012:	e83a                	sd	a4,16(sp)
ffffffffc0202014:	ec32                	sd	a2,24(sp)
ffffffffc0202016:	8e9fe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020201a:	000b3797          	auipc	a5,0xb3
ffffffffc020201e:	64e7b783          	ld	a5,1614(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202022:	4505                	li	a0,1
ffffffffc0202024:	6f9c                	ld	a5,24(a5)
ffffffffc0202026:	9782                	jalr	a5
ffffffffc0202028:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020202a:	8cffe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020202e:	6862                	ld	a6,24(sp)
ffffffffc0202030:	6742                	ld	a4,16(sp)
ffffffffc0202032:	67a2                	ld	a5,8(sp)
ffffffffc0202034:	bdbd                	j	ffffffffc0201eb2 <get_pte+0x50>
        intr_disable();
ffffffffc0202036:	e83e                	sd	a5,16(sp)
ffffffffc0202038:	8c7fe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc020203c:	000b3717          	auipc	a4,0xb3
ffffffffc0202040:	62c73703          	ld	a4,1580(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202044:	4505                	li	a0,1
ffffffffc0202046:	6f18                	ld	a4,24(a4)
ffffffffc0202048:	9702                	jalr	a4
ffffffffc020204a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020204c:	8adfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202050:	6722                	ld	a4,8(sp)
ffffffffc0202052:	67c2                	ld	a5,16(sp)
ffffffffc0202054:	000b3897          	auipc	a7,0xb3
ffffffffc0202058:	62c88893          	addi	a7,a7,1580 # ffffffffc02b5680 <va_pa_offset>
ffffffffc020205c:	bf31                	j	ffffffffc0201f78 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020205e:	00004617          	auipc	a2,0x4
ffffffffc0202062:	60260613          	addi	a2,a2,1538 # ffffffffc0206660 <etext+0xdbc>
ffffffffc0202066:	0fa00593          	li	a1,250
ffffffffc020206a:	00004517          	auipc	a0,0x4
ffffffffc020206e:	6e650513          	addi	a0,a0,1766 # ffffffffc0206750 <etext+0xeac>
ffffffffc0202072:	bd8fe0ef          	jal	ffffffffc020044a <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202076:	00004617          	auipc	a2,0x4
ffffffffc020207a:	5ea60613          	addi	a2,a2,1514 # ffffffffc0206660 <etext+0xdbc>
ffffffffc020207e:	0ed00593          	li	a1,237
ffffffffc0202082:	00004517          	auipc	a0,0x4
ffffffffc0202086:	6ce50513          	addi	a0,a0,1742 # ffffffffc0206750 <etext+0xeac>
ffffffffc020208a:	bc0fe0ef          	jal	ffffffffc020044a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020208e:	86aa                	mv	a3,a0
ffffffffc0202090:	00004617          	auipc	a2,0x4
ffffffffc0202094:	5d060613          	addi	a2,a2,1488 # ffffffffc0206660 <etext+0xdbc>
ffffffffc0202098:	0e900593          	li	a1,233
ffffffffc020209c:	00004517          	auipc	a0,0x4
ffffffffc02020a0:	6b450513          	addi	a0,a0,1716 # ffffffffc0206750 <etext+0xeac>
ffffffffc02020a4:	ba6fe0ef          	jal	ffffffffc020044a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020a8:	00004617          	auipc	a2,0x4
ffffffffc02020ac:	5b860613          	addi	a2,a2,1464 # ffffffffc0206660 <etext+0xdbc>
ffffffffc02020b0:	0f700593          	li	a1,247
ffffffffc02020b4:	00004517          	auipc	a0,0x4
ffffffffc02020b8:	69c50513          	addi	a0,a0,1692 # ffffffffc0206750 <etext+0xeac>
ffffffffc02020bc:	b8efe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02020c0 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02020c0:	1141                	addi	sp,sp,-16
ffffffffc02020c2:	e022                	sd	s0,0(sp)
ffffffffc02020c4:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020c6:	4601                	li	a2,0
{
ffffffffc02020c8:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020ca:	d99ff0ef          	jal	ffffffffc0201e62 <get_pte>
    if (ptep_store != NULL)
ffffffffc02020ce:	c011                	beqz	s0,ffffffffc02020d2 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02020d0:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02020d2:	c511                	beqz	a0,ffffffffc02020de <get_page+0x1e>
ffffffffc02020d4:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02020d6:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02020d8:	0017f713          	andi	a4,a5,1
ffffffffc02020dc:	e709                	bnez	a4,ffffffffc02020e6 <get_page+0x26>
}
ffffffffc02020de:	60a2                	ld	ra,8(sp)
ffffffffc02020e0:	6402                	ld	s0,0(sp)
ffffffffc02020e2:	0141                	addi	sp,sp,16
ffffffffc02020e4:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02020e6:	000b3717          	auipc	a4,0xb3
ffffffffc02020ea:	5a273703          	ld	a4,1442(a4) # ffffffffc02b5688 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02020ee:	078a                	slli	a5,a5,0x2
ffffffffc02020f0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020f2:	00e7ff63          	bgeu	a5,a4,ffffffffc0202110 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc02020f6:	000b3517          	auipc	a0,0xb3
ffffffffc02020fa:	59a53503          	ld	a0,1434(a0) # ffffffffc02b5690 <pages>
ffffffffc02020fe:	60a2                	ld	ra,8(sp)
ffffffffc0202100:	6402                	ld	s0,0(sp)
ffffffffc0202102:	079a                	slli	a5,a5,0x6
ffffffffc0202104:	fe000737          	lui	a4,0xfe000
ffffffffc0202108:	97ba                	add	a5,a5,a4
ffffffffc020210a:	953e                	add	a0,a0,a5
ffffffffc020210c:	0141                	addi	sp,sp,16
ffffffffc020210e:	8082                	ret
ffffffffc0202110:	c8fff0ef          	jal	ffffffffc0201d9e <pa2page.part.0>

ffffffffc0202114 <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202114:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202116:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020211a:	e486                	sd	ra,72(sp)
ffffffffc020211c:	e0a2                	sd	s0,64(sp)
ffffffffc020211e:	fc26                	sd	s1,56(sp)
ffffffffc0202120:	f84a                	sd	s2,48(sp)
ffffffffc0202122:	f44e                	sd	s3,40(sp)
ffffffffc0202124:	f052                	sd	s4,32(sp)
ffffffffc0202126:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202128:	03479713          	slli	a4,a5,0x34
ffffffffc020212c:	ef61                	bnez	a4,ffffffffc0202204 <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc020212e:	00200a37          	lui	s4,0x200
ffffffffc0202132:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc0202136:	0145b733          	sltu	a4,a1,s4
ffffffffc020213a:	0017b793          	seqz	a5,a5
ffffffffc020213e:	8fd9                	or	a5,a5,a4
ffffffffc0202140:	842e                	mv	s0,a1
ffffffffc0202142:	84b2                	mv	s1,a2
ffffffffc0202144:	e3e5                	bnez	a5,ffffffffc0202224 <unmap_range+0x110>
ffffffffc0202146:	4785                	li	a5,1
ffffffffc0202148:	07fe                	slli	a5,a5,0x1f
ffffffffc020214a:	0785                	addi	a5,a5,1
ffffffffc020214c:	892a                	mv	s2,a0
ffffffffc020214e:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202150:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc0202154:	0cf67863          	bgeu	a2,a5,ffffffffc0202224 <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202158:	4601                	li	a2,0
ffffffffc020215a:	85a2                	mv	a1,s0
ffffffffc020215c:	854a                	mv	a0,s2
ffffffffc020215e:	d05ff0ef          	jal	ffffffffc0201e62 <get_pte>
ffffffffc0202162:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc0202164:	cd31                	beqz	a0,ffffffffc02021c0 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc0202166:	6118                	ld	a4,0(a0)
ffffffffc0202168:	ef11                	bnez	a4,ffffffffc0202184 <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020216a:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc020216c:	c019                	beqz	s0,ffffffffc0202172 <unmap_range+0x5e>
ffffffffc020216e:	fe9465e3          	bltu	s0,s1,ffffffffc0202158 <unmap_range+0x44>
}
ffffffffc0202172:	60a6                	ld	ra,72(sp)
ffffffffc0202174:	6406                	ld	s0,64(sp)
ffffffffc0202176:	74e2                	ld	s1,56(sp)
ffffffffc0202178:	7942                	ld	s2,48(sp)
ffffffffc020217a:	79a2                	ld	s3,40(sp)
ffffffffc020217c:	7a02                	ld	s4,32(sp)
ffffffffc020217e:	6ae2                	ld	s5,24(sp)
ffffffffc0202180:	6161                	addi	sp,sp,80
ffffffffc0202182:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202184:	00177693          	andi	a3,a4,1
ffffffffc0202188:	d2ed                	beqz	a3,ffffffffc020216a <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc020218a:	000b3697          	auipc	a3,0xb3
ffffffffc020218e:	4fe6b683          	ld	a3,1278(a3) # ffffffffc02b5688 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202192:	070a                	slli	a4,a4,0x2
ffffffffc0202194:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202196:	0ad77763          	bgeu	a4,a3,ffffffffc0202244 <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc020219a:	000b3517          	auipc	a0,0xb3
ffffffffc020219e:	4f653503          	ld	a0,1270(a0) # ffffffffc02b5690 <pages>
ffffffffc02021a2:	071a                	slli	a4,a4,0x6
ffffffffc02021a4:	fe0006b7          	lui	a3,0xfe000
ffffffffc02021a8:	9736                	add	a4,a4,a3
ffffffffc02021aa:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc02021ac:	4118                	lw	a4,0(a0)
ffffffffc02021ae:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd4a937>
ffffffffc02021b0:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02021b2:	cb19                	beqz	a4,ffffffffc02021c8 <unmap_range+0xb4>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02021b4:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02021b8:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02021bc:	944e                	add	s0,s0,s3
ffffffffc02021be:	b77d                	j	ffffffffc020216c <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021c0:	9452                	add	s0,s0,s4
ffffffffc02021c2:	01547433          	and	s0,s0,s5
            continue;
ffffffffc02021c6:	b75d                	j	ffffffffc020216c <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02021c8:	10002773          	csrr	a4,sstatus
ffffffffc02021cc:	8b09                	andi	a4,a4,2
ffffffffc02021ce:	eb19                	bnez	a4,ffffffffc02021e4 <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc02021d0:	000b3717          	auipc	a4,0xb3
ffffffffc02021d4:	49873703          	ld	a4,1176(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc02021d8:	4585                	li	a1,1
ffffffffc02021da:	e03e                	sd	a5,0(sp)
ffffffffc02021dc:	7318                	ld	a4,32(a4)
ffffffffc02021de:	9702                	jalr	a4
    if (flag)
ffffffffc02021e0:	6782                	ld	a5,0(sp)
ffffffffc02021e2:	bfc9                	j	ffffffffc02021b4 <unmap_range+0xa0>
        intr_disable();
ffffffffc02021e4:	e43e                	sd	a5,8(sp)
ffffffffc02021e6:	e02a                	sd	a0,0(sp)
ffffffffc02021e8:	f16fe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc02021ec:	000b3717          	auipc	a4,0xb3
ffffffffc02021f0:	47c73703          	ld	a4,1148(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc02021f4:	6502                	ld	a0,0(sp)
ffffffffc02021f6:	4585                	li	a1,1
ffffffffc02021f8:	7318                	ld	a4,32(a4)
ffffffffc02021fa:	9702                	jalr	a4
        intr_enable();
ffffffffc02021fc:	efcfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202200:	67a2                	ld	a5,8(sp)
ffffffffc0202202:	bf4d                	j	ffffffffc02021b4 <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202204:	00004697          	auipc	a3,0x4
ffffffffc0202208:	55c68693          	addi	a3,a3,1372 # ffffffffc0206760 <etext+0xebc>
ffffffffc020220c:	00004617          	auipc	a2,0x4
ffffffffc0202210:	0a460613          	addi	a2,a2,164 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0202214:	12200593          	li	a1,290
ffffffffc0202218:	00004517          	auipc	a0,0x4
ffffffffc020221c:	53850513          	addi	a0,a0,1336 # ffffffffc0206750 <etext+0xeac>
ffffffffc0202220:	a2afe0ef          	jal	ffffffffc020044a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202224:	00004697          	auipc	a3,0x4
ffffffffc0202228:	56c68693          	addi	a3,a3,1388 # ffffffffc0206790 <etext+0xeec>
ffffffffc020222c:	00004617          	auipc	a2,0x4
ffffffffc0202230:	08460613          	addi	a2,a2,132 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0202234:	12300593          	li	a1,291
ffffffffc0202238:	00004517          	auipc	a0,0x4
ffffffffc020223c:	51850513          	addi	a0,a0,1304 # ffffffffc0206750 <etext+0xeac>
ffffffffc0202240:	a0afe0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0202244:	b5bff0ef          	jal	ffffffffc0201d9e <pa2page.part.0>

ffffffffc0202248 <exit_range>:
{
ffffffffc0202248:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020224a:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020224e:	ed06                	sd	ra,152(sp)
ffffffffc0202250:	e922                	sd	s0,144(sp)
ffffffffc0202252:	e526                	sd	s1,136(sp)
ffffffffc0202254:	e14a                	sd	s2,128(sp)
ffffffffc0202256:	fcce                	sd	s3,120(sp)
ffffffffc0202258:	f8d2                	sd	s4,112(sp)
ffffffffc020225a:	f4d6                	sd	s5,104(sp)
ffffffffc020225c:	f0da                	sd	s6,96(sp)
ffffffffc020225e:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202260:	17d2                	slli	a5,a5,0x34
ffffffffc0202262:	22079263          	bnez	a5,ffffffffc0202486 <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc0202266:	00200937          	lui	s2,0x200
ffffffffc020226a:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020226e:	0125b733          	sltu	a4,a1,s2
ffffffffc0202272:	0017b793          	seqz	a5,a5
ffffffffc0202276:	8fd9                	or	a5,a5,a4
ffffffffc0202278:	26079263          	bnez	a5,ffffffffc02024dc <exit_range+0x294>
ffffffffc020227c:	4785                	li	a5,1
ffffffffc020227e:	07fe                	slli	a5,a5,0x1f
ffffffffc0202280:	0785                	addi	a5,a5,1
ffffffffc0202282:	24f67d63          	bgeu	a2,a5,ffffffffc02024dc <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202286:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020228a:	ffe007b7          	lui	a5,0xffe00
ffffffffc020228e:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202290:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202292:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc0202296:	000b3a97          	auipc	s5,0xb3
ffffffffc020229a:	3f2a8a93          	addi	s5,s5,1010 # ffffffffc02b5688 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020229e:	400009b7          	lui	s3,0x40000
ffffffffc02022a2:	a809                	j	ffffffffc02022b4 <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc02022a4:	013487b3          	add	a5,s1,s3
ffffffffc02022a8:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02022ac:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02022ae:	c3f1                	beqz	a5,ffffffffc0202372 <exit_range+0x12a>
ffffffffc02022b0:	0cc7f163          	bgeu	a5,a2,ffffffffc0202372 <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02022b4:	01e4d413          	srli	s0,s1,0x1e
ffffffffc02022b8:	1ff47413          	andi	s0,s0,511
ffffffffc02022bc:	040e                	slli	s0,s0,0x3
ffffffffc02022be:	9452                	add	s0,s0,s4
ffffffffc02022c0:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc02022c4:	0018f793          	andi	a5,a7,1
ffffffffc02022c8:	dff1                	beqz	a5,ffffffffc02022a4 <exit_range+0x5c>
ffffffffc02022ca:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02022ce:	088a                	slli	a7,a7,0x2
ffffffffc02022d0:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc02022d4:	20f8f263          	bgeu	a7,a5,ffffffffc02024d8 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02022d8:	fff802b7          	lui	t0,0xfff80
ffffffffc02022dc:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc02022e0:	000803b7          	lui	t2,0x80
ffffffffc02022e4:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc02022e8:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02022ec:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc02022ee:	1cf77863          	bgeu	a4,a5,ffffffffc02024be <exit_range+0x276>
ffffffffc02022f2:	000b3f97          	auipc	t6,0xb3
ffffffffc02022f6:	38ef8f93          	addi	t6,t6,910 # ffffffffc02b5680 <va_pa_offset>
ffffffffc02022fa:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc02022fe:	4e85                	li	t4,1
ffffffffc0202300:	6b05                	lui	s6,0x1
ffffffffc0202302:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202304:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202308:	01585713          	srli	a4,a6,0x15
ffffffffc020230c:	1ff77713          	andi	a4,a4,511
ffffffffc0202310:	070e                	slli	a4,a4,0x3
ffffffffc0202312:	9772                	add	a4,a4,t3
ffffffffc0202314:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc0202316:	0017f693          	andi	a3,a5,1
ffffffffc020231a:	e6bd                	bnez	a3,ffffffffc0202388 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc020231c:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc020231e:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202320:	00080863          	beqz	a6,ffffffffc0202330 <exit_range+0xe8>
ffffffffc0202324:	879a                	mv	a5,t1
ffffffffc0202326:	00667363          	bgeu	a2,t1,ffffffffc020232c <exit_range+0xe4>
ffffffffc020232a:	87b2                	mv	a5,a2
ffffffffc020232c:	fcf86ee3          	bltu	a6,a5,ffffffffc0202308 <exit_range+0xc0>
            if (free_pd0)
ffffffffc0202330:	f60e8ae3          	beqz	t4,ffffffffc02022a4 <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc0202334:	000ab783          	ld	a5,0(s5)
ffffffffc0202338:	1af8f063          	bgeu	a7,a5,ffffffffc02024d8 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc020233c:	000b3517          	auipc	a0,0xb3
ffffffffc0202340:	35453503          	ld	a0,852(a0) # ffffffffc02b5690 <pages>
ffffffffc0202344:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202346:	100027f3          	csrr	a5,sstatus
ffffffffc020234a:	8b89                	andi	a5,a5,2
ffffffffc020234c:	10079b63          	bnez	a5,ffffffffc0202462 <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc0202350:	000b3797          	auipc	a5,0xb3
ffffffffc0202354:	3187b783          	ld	a5,792(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202358:	4585                	li	a1,1
ffffffffc020235a:	e432                	sd	a2,8(sp)
ffffffffc020235c:	739c                	ld	a5,32(a5)
ffffffffc020235e:	9782                	jalr	a5
ffffffffc0202360:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202362:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc0202366:	013487b3          	add	a5,s1,s3
ffffffffc020236a:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc020236e:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202370:	f3a1                	bnez	a5,ffffffffc02022b0 <exit_range+0x68>
}
ffffffffc0202372:	60ea                	ld	ra,152(sp)
ffffffffc0202374:	644a                	ld	s0,144(sp)
ffffffffc0202376:	64aa                	ld	s1,136(sp)
ffffffffc0202378:	690a                	ld	s2,128(sp)
ffffffffc020237a:	79e6                	ld	s3,120(sp)
ffffffffc020237c:	7a46                	ld	s4,112(sp)
ffffffffc020237e:	7aa6                	ld	s5,104(sp)
ffffffffc0202380:	7b06                	ld	s6,96(sp)
ffffffffc0202382:	6be6                	ld	s7,88(sp)
ffffffffc0202384:	610d                	addi	sp,sp,160
ffffffffc0202386:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202388:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020238c:	078a                	slli	a5,a5,0x2
ffffffffc020238e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202390:	14a7f463          	bgeu	a5,a0,ffffffffc02024d8 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202394:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc0202396:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc020239a:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020239e:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc02023a2:	10abf263          	bgeu	s7,a0,ffffffffc02024a6 <exit_range+0x25e>
ffffffffc02023a6:	000fb783          	ld	a5,0(t6)
ffffffffc02023aa:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023ac:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc02023b0:	629c                	ld	a5,0(a3)
ffffffffc02023b2:	8b85                	andi	a5,a5,1
ffffffffc02023b4:	f7ad                	bnez	a5,ffffffffc020231e <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023b6:	06a1                	addi	a3,a3,8
ffffffffc02023b8:	fea69ce3          	bne	a3,a0,ffffffffc02023b0 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc02023bc:	000b3517          	auipc	a0,0xb3
ffffffffc02023c0:	2d453503          	ld	a0,724(a0) # ffffffffc02b5690 <pages>
ffffffffc02023c4:	952e                	add	a0,a0,a1
ffffffffc02023c6:	100027f3          	csrr	a5,sstatus
ffffffffc02023ca:	8b89                	andi	a5,a5,2
ffffffffc02023cc:	e3b9                	bnez	a5,ffffffffc0202412 <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc02023ce:	000b3797          	auipc	a5,0xb3
ffffffffc02023d2:	29a7b783          	ld	a5,666(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc02023d6:	4585                	li	a1,1
ffffffffc02023d8:	e0b2                	sd	a2,64(sp)
ffffffffc02023da:	739c                	ld	a5,32(a5)
ffffffffc02023dc:	fc1a                	sd	t1,56(sp)
ffffffffc02023de:	f846                	sd	a7,48(sp)
ffffffffc02023e0:	f47a                	sd	t5,40(sp)
ffffffffc02023e2:	f072                	sd	t3,32(sp)
ffffffffc02023e4:	ec76                	sd	t4,24(sp)
ffffffffc02023e6:	e842                	sd	a6,16(sp)
ffffffffc02023e8:	e43a                	sd	a4,8(sp)
ffffffffc02023ea:	9782                	jalr	a5
    if (flag)
ffffffffc02023ec:	6722                	ld	a4,8(sp)
ffffffffc02023ee:	6842                	ld	a6,16(sp)
ffffffffc02023f0:	6ee2                	ld	t4,24(sp)
ffffffffc02023f2:	7e02                	ld	t3,32(sp)
ffffffffc02023f4:	7f22                	ld	t5,40(sp)
ffffffffc02023f6:	78c2                	ld	a7,48(sp)
ffffffffc02023f8:	7362                	ld	t1,56(sp)
ffffffffc02023fa:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc02023fc:	fff802b7          	lui	t0,0xfff80
ffffffffc0202400:	000803b7          	lui	t2,0x80
ffffffffc0202404:	000b3f97          	auipc	t6,0xb3
ffffffffc0202408:	27cf8f93          	addi	t6,t6,636 # ffffffffc02b5680 <va_pa_offset>
ffffffffc020240c:	00073023          	sd	zero,0(a4)
ffffffffc0202410:	b739                	j	ffffffffc020231e <exit_range+0xd6>
        intr_disable();
ffffffffc0202412:	e4b2                	sd	a2,72(sp)
ffffffffc0202414:	e09a                	sd	t1,64(sp)
ffffffffc0202416:	fc46                	sd	a7,56(sp)
ffffffffc0202418:	f47a                	sd	t5,40(sp)
ffffffffc020241a:	f072                	sd	t3,32(sp)
ffffffffc020241c:	ec76                	sd	t4,24(sp)
ffffffffc020241e:	e842                	sd	a6,16(sp)
ffffffffc0202420:	e43a                	sd	a4,8(sp)
ffffffffc0202422:	f82a                	sd	a0,48(sp)
ffffffffc0202424:	cdafe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202428:	000b3797          	auipc	a5,0xb3
ffffffffc020242c:	2407b783          	ld	a5,576(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202430:	7542                	ld	a0,48(sp)
ffffffffc0202432:	4585                	li	a1,1
ffffffffc0202434:	739c                	ld	a5,32(a5)
ffffffffc0202436:	9782                	jalr	a5
        intr_enable();
ffffffffc0202438:	cc0fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020243c:	6722                	ld	a4,8(sp)
ffffffffc020243e:	6626                	ld	a2,72(sp)
ffffffffc0202440:	6306                	ld	t1,64(sp)
ffffffffc0202442:	78e2                	ld	a7,56(sp)
ffffffffc0202444:	7f22                	ld	t5,40(sp)
ffffffffc0202446:	7e02                	ld	t3,32(sp)
ffffffffc0202448:	6ee2                	ld	t4,24(sp)
ffffffffc020244a:	6842                	ld	a6,16(sp)
ffffffffc020244c:	000b3f97          	auipc	t6,0xb3
ffffffffc0202450:	234f8f93          	addi	t6,t6,564 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0202454:	000803b7          	lui	t2,0x80
ffffffffc0202458:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc020245c:	00073023          	sd	zero,0(a4)
ffffffffc0202460:	bd7d                	j	ffffffffc020231e <exit_range+0xd6>
        intr_disable();
ffffffffc0202462:	e832                	sd	a2,16(sp)
ffffffffc0202464:	e42a                	sd	a0,8(sp)
ffffffffc0202466:	c98fe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020246a:	000b3797          	auipc	a5,0xb3
ffffffffc020246e:	1fe7b783          	ld	a5,510(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202472:	6522                	ld	a0,8(sp)
ffffffffc0202474:	4585                	li	a1,1
ffffffffc0202476:	739c                	ld	a5,32(a5)
ffffffffc0202478:	9782                	jalr	a5
        intr_enable();
ffffffffc020247a:	c7efe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020247e:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202480:	00043023          	sd	zero,0(s0)
ffffffffc0202484:	b5cd                	j	ffffffffc0202366 <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202486:	00004697          	auipc	a3,0x4
ffffffffc020248a:	2da68693          	addi	a3,a3,730 # ffffffffc0206760 <etext+0xebc>
ffffffffc020248e:	00004617          	auipc	a2,0x4
ffffffffc0202492:	e2260613          	addi	a2,a2,-478 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0202496:	13700593          	li	a1,311
ffffffffc020249a:	00004517          	auipc	a0,0x4
ffffffffc020249e:	2b650513          	addi	a0,a0,694 # ffffffffc0206750 <etext+0xeac>
ffffffffc02024a2:	fa9fd0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc02024a6:	00004617          	auipc	a2,0x4
ffffffffc02024aa:	1ba60613          	addi	a2,a2,442 # ffffffffc0206660 <etext+0xdbc>
ffffffffc02024ae:	07100593          	li	a1,113
ffffffffc02024b2:	00004517          	auipc	a0,0x4
ffffffffc02024b6:	1d650513          	addi	a0,a0,470 # ffffffffc0206688 <etext+0xde4>
ffffffffc02024ba:	f91fd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc02024be:	86f2                	mv	a3,t3
ffffffffc02024c0:	00004617          	auipc	a2,0x4
ffffffffc02024c4:	1a060613          	addi	a2,a2,416 # ffffffffc0206660 <etext+0xdbc>
ffffffffc02024c8:	07100593          	li	a1,113
ffffffffc02024cc:	00004517          	auipc	a0,0x4
ffffffffc02024d0:	1bc50513          	addi	a0,a0,444 # ffffffffc0206688 <etext+0xde4>
ffffffffc02024d4:	f77fd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc02024d8:	8c7ff0ef          	jal	ffffffffc0201d9e <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02024dc:	00004697          	auipc	a3,0x4
ffffffffc02024e0:	2b468693          	addi	a3,a3,692 # ffffffffc0206790 <etext+0xeec>
ffffffffc02024e4:	00004617          	auipc	a2,0x4
ffffffffc02024e8:	dcc60613          	addi	a2,a2,-564 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02024ec:	13800593          	li	a1,312
ffffffffc02024f0:	00004517          	auipc	a0,0x4
ffffffffc02024f4:	26050513          	addi	a0,a0,608 # ffffffffc0206750 <etext+0xeac>
ffffffffc02024f8:	f53fd0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02024fc <copy_range>:
{
ffffffffc02024fc:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02024fe:	00d667b3          	or	a5,a2,a3
{
ffffffffc0202502:	f486                	sd	ra,104(sp)
ffffffffc0202504:	f0a2                	sd	s0,96(sp)
ffffffffc0202506:	eca6                	sd	s1,88(sp)
ffffffffc0202508:	e8ca                	sd	s2,80(sp)
ffffffffc020250a:	e4ce                	sd	s3,72(sp)
ffffffffc020250c:	e0d2                	sd	s4,64(sp)
ffffffffc020250e:	fc56                	sd	s5,56(sp)
ffffffffc0202510:	f85a                	sd	s6,48(sp)
ffffffffc0202512:	f45e                	sd	s7,40(sp)
ffffffffc0202514:	f062                	sd	s8,32(sp)
ffffffffc0202516:	ec66                	sd	s9,24(sp)
ffffffffc0202518:	e86a                	sd	s10,16(sp)
ffffffffc020251a:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020251c:	03479713          	slli	a4,a5,0x34
ffffffffc0202520:	18071163          	bnez	a4,ffffffffc02026a2 <copy_range+0x1a6>
    assert(USER_ACCESS(start, end));
ffffffffc0202524:	00200cb7          	lui	s9,0x200
ffffffffc0202528:	00d637b3          	sltu	a5,a2,a3
ffffffffc020252c:	01963733          	sltu	a4,a2,s9
ffffffffc0202530:	0017b793          	seqz	a5,a5
ffffffffc0202534:	8fd9                	or	a5,a5,a4
ffffffffc0202536:	8432                	mv	s0,a2
ffffffffc0202538:	84b6                	mv	s1,a3
ffffffffc020253a:	14079463          	bnez	a5,ffffffffc0202682 <copy_range+0x186>
ffffffffc020253e:	4785                	li	a5,1
ffffffffc0202540:	07fe                	slli	a5,a5,0x1f
ffffffffc0202542:	0785                	addi	a5,a5,1
ffffffffc0202544:	12f6ff63          	bgeu	a3,a5,ffffffffc0202682 <copy_range+0x186>
ffffffffc0202548:	8aaa                	mv	s5,a0
ffffffffc020254a:	892e                	mv	s2,a1
ffffffffc020254c:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage)
ffffffffc020254e:	000b3c17          	auipc	s8,0xb3
ffffffffc0202552:	13ac0c13          	addi	s8,s8,314 # ffffffffc02b5688 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202556:	000b3b97          	auipc	s7,0xb3
ffffffffc020255a:	13ab8b93          	addi	s7,s7,314 # ffffffffc02b5690 <pages>
ffffffffc020255e:	fff80b37          	lui	s6,0xfff80
        page = pmm_manager->alloc_pages(n);
ffffffffc0202562:	000b3a17          	auipc	s4,0xb3
ffffffffc0202566:	106a0a13          	addi	s4,s4,262 # ffffffffc02b5668 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020256a:	4601                	li	a2,0
ffffffffc020256c:	85a2                	mv	a1,s0
ffffffffc020256e:	854a                	mv	a0,s2
ffffffffc0202570:	8f3ff0ef          	jal	ffffffffc0201e62 <get_pte>
ffffffffc0202574:	8d2a                	mv	s10,a0
        if (ptep == NULL)
ffffffffc0202576:	cd41                	beqz	a0,ffffffffc020260e <copy_range+0x112>
        if (*ptep & PTE_V)
ffffffffc0202578:	611c                	ld	a5,0(a0)
ffffffffc020257a:	8b85                	andi	a5,a5,1
ffffffffc020257c:	e78d                	bnez	a5,ffffffffc02025a6 <copy_range+0xaa>
        start += PGSIZE;
ffffffffc020257e:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0202580:	c019                	beqz	s0,ffffffffc0202586 <copy_range+0x8a>
ffffffffc0202582:	fe9464e3          	bltu	s0,s1,ffffffffc020256a <copy_range+0x6e>
    return 0;
ffffffffc0202586:	4501                	li	a0,0
}
ffffffffc0202588:	70a6                	ld	ra,104(sp)
ffffffffc020258a:	7406                	ld	s0,96(sp)
ffffffffc020258c:	64e6                	ld	s1,88(sp)
ffffffffc020258e:	6946                	ld	s2,80(sp)
ffffffffc0202590:	69a6                	ld	s3,72(sp)
ffffffffc0202592:	6a06                	ld	s4,64(sp)
ffffffffc0202594:	7ae2                	ld	s5,56(sp)
ffffffffc0202596:	7b42                	ld	s6,48(sp)
ffffffffc0202598:	7ba2                	ld	s7,40(sp)
ffffffffc020259a:	7c02                	ld	s8,32(sp)
ffffffffc020259c:	6ce2                	ld	s9,24(sp)
ffffffffc020259e:	6d42                	ld	s10,16(sp)
ffffffffc02025a0:	6da2                	ld	s11,8(sp)
ffffffffc02025a2:	6165                	addi	sp,sp,112
ffffffffc02025a4:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02025a6:	4605                	li	a2,1
ffffffffc02025a8:	85a2                	mv	a1,s0
ffffffffc02025aa:	8556                	mv	a0,s5
ffffffffc02025ac:	8b7ff0ef          	jal	ffffffffc0201e62 <get_pte>
ffffffffc02025b0:	cd3d                	beqz	a0,ffffffffc020262e <copy_range+0x132>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02025b2:	000d3783          	ld	a5,0(s10)
    if (!(pte & PTE_V))
ffffffffc02025b6:	0017f713          	andi	a4,a5,1
ffffffffc02025ba:	cf25                	beqz	a4,ffffffffc0202632 <copy_range+0x136>
    if (PPN(pa) >= npage)
ffffffffc02025bc:	000c3703          	ld	a4,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02025c0:	078a                	slli	a5,a5,0x2
ffffffffc02025c2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025c4:	0ae7f363          	bgeu	a5,a4,ffffffffc020266a <copy_range+0x16e>
    return &pages[PPN(pa) - nbase];
ffffffffc02025c8:	000bbd83          	ld	s11,0(s7)
ffffffffc02025cc:	97da                	add	a5,a5,s6
ffffffffc02025ce:	079a                	slli	a5,a5,0x6
ffffffffc02025d0:	9dbe                	add	s11,s11,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025d2:	100027f3          	csrr	a5,sstatus
ffffffffc02025d6:	8b89                	andi	a5,a5,2
ffffffffc02025d8:	e3a1                	bnez	a5,ffffffffc0202618 <copy_range+0x11c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02025da:	000a3783          	ld	a5,0(s4)
ffffffffc02025de:	4505                	li	a0,1
ffffffffc02025e0:	6f9c                	ld	a5,24(a5)
ffffffffc02025e2:	9782                	jalr	a5
ffffffffc02025e4:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc02025e6:	060d8263          	beqz	s11,ffffffffc020264a <copy_range+0x14e>
            assert(npage != NULL);
ffffffffc02025ea:	f80d1ae3          	bnez	s10,ffffffffc020257e <copy_range+0x82>
ffffffffc02025ee:	00004697          	auipc	a3,0x4
ffffffffc02025f2:	1f268693          	addi	a3,a3,498 # ffffffffc02067e0 <etext+0xf3c>
ffffffffc02025f6:	00004617          	auipc	a2,0x4
ffffffffc02025fa:	cba60613          	addi	a2,a2,-838 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02025fe:	19700593          	li	a1,407
ffffffffc0202602:	00004517          	auipc	a0,0x4
ffffffffc0202606:	14e50513          	addi	a0,a0,334 # ffffffffc0206750 <etext+0xeac>
ffffffffc020260a:	e41fd0ef          	jal	ffffffffc020044a <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020260e:	9466                	add	s0,s0,s9
ffffffffc0202610:	ffe007b7          	lui	a5,0xffe00
ffffffffc0202614:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc0202616:	b7ad                	j	ffffffffc0202580 <copy_range+0x84>
        intr_disable();
ffffffffc0202618:	ae6fe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020261c:	000a3783          	ld	a5,0(s4)
ffffffffc0202620:	4505                	li	a0,1
ffffffffc0202622:	6f9c                	ld	a5,24(a5)
ffffffffc0202624:	9782                	jalr	a5
ffffffffc0202626:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc0202628:	ad0fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020262c:	bf6d                	j	ffffffffc02025e6 <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc020262e:	5571                	li	a0,-4
ffffffffc0202630:	bfa1                	j	ffffffffc0202588 <copy_range+0x8c>
        panic("pte2page called with invalid pte");
ffffffffc0202632:	00004617          	auipc	a2,0x4
ffffffffc0202636:	17660613          	addi	a2,a2,374 # ffffffffc02067a8 <etext+0xf04>
ffffffffc020263a:	07f00593          	li	a1,127
ffffffffc020263e:	00004517          	auipc	a0,0x4
ffffffffc0202642:	04a50513          	addi	a0,a0,74 # ffffffffc0206688 <etext+0xde4>
ffffffffc0202646:	e05fd0ef          	jal	ffffffffc020044a <__panic>
            assert(page != NULL);
ffffffffc020264a:	00004697          	auipc	a3,0x4
ffffffffc020264e:	18668693          	addi	a3,a3,390 # ffffffffc02067d0 <etext+0xf2c>
ffffffffc0202652:	00004617          	auipc	a2,0x4
ffffffffc0202656:	c5e60613          	addi	a2,a2,-930 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020265a:	19600593          	li	a1,406
ffffffffc020265e:	00004517          	auipc	a0,0x4
ffffffffc0202662:	0f250513          	addi	a0,a0,242 # ffffffffc0206750 <etext+0xeac>
ffffffffc0202666:	de5fd0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020266a:	00004617          	auipc	a2,0x4
ffffffffc020266e:	0c660613          	addi	a2,a2,198 # ffffffffc0206730 <etext+0xe8c>
ffffffffc0202672:	06900593          	li	a1,105
ffffffffc0202676:	00004517          	auipc	a0,0x4
ffffffffc020267a:	01250513          	addi	a0,a0,18 # ffffffffc0206688 <etext+0xde4>
ffffffffc020267e:	dcdfd0ef          	jal	ffffffffc020044a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202682:	00004697          	auipc	a3,0x4
ffffffffc0202686:	10e68693          	addi	a3,a3,270 # ffffffffc0206790 <etext+0xeec>
ffffffffc020268a:	00004617          	auipc	a2,0x4
ffffffffc020268e:	c2660613          	addi	a2,a2,-986 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0202692:	17e00593          	li	a1,382
ffffffffc0202696:	00004517          	auipc	a0,0x4
ffffffffc020269a:	0ba50513          	addi	a0,a0,186 # ffffffffc0206750 <etext+0xeac>
ffffffffc020269e:	dadfd0ef          	jal	ffffffffc020044a <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02026a2:	00004697          	auipc	a3,0x4
ffffffffc02026a6:	0be68693          	addi	a3,a3,190 # ffffffffc0206760 <etext+0xebc>
ffffffffc02026aa:	00004617          	auipc	a2,0x4
ffffffffc02026ae:	c0660613          	addi	a2,a2,-1018 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02026b2:	17d00593          	li	a1,381
ffffffffc02026b6:	00004517          	auipc	a0,0x4
ffffffffc02026ba:	09a50513          	addi	a0,a0,154 # ffffffffc0206750 <etext+0xeac>
ffffffffc02026be:	d8dfd0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02026c2 <page_remove>:
{
ffffffffc02026c2:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02026c4:	4601                	li	a2,0
{
ffffffffc02026c6:	e822                	sd	s0,16(sp)
ffffffffc02026c8:	ec06                	sd	ra,24(sp)
ffffffffc02026ca:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02026cc:	f96ff0ef          	jal	ffffffffc0201e62 <get_pte>
    if (ptep != NULL)
ffffffffc02026d0:	c511                	beqz	a0,ffffffffc02026dc <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc02026d2:	6118                	ld	a4,0(a0)
ffffffffc02026d4:	87aa                	mv	a5,a0
ffffffffc02026d6:	00177693          	andi	a3,a4,1
ffffffffc02026da:	e689                	bnez	a3,ffffffffc02026e4 <page_remove+0x22>
}
ffffffffc02026dc:	60e2                	ld	ra,24(sp)
ffffffffc02026de:	6442                	ld	s0,16(sp)
ffffffffc02026e0:	6105                	addi	sp,sp,32
ffffffffc02026e2:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02026e4:	000b3697          	auipc	a3,0xb3
ffffffffc02026e8:	fa46b683          	ld	a3,-92(a3) # ffffffffc02b5688 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02026ec:	070a                	slli	a4,a4,0x2
ffffffffc02026ee:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02026f0:	06d77563          	bgeu	a4,a3,ffffffffc020275a <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02026f4:	000b3517          	auipc	a0,0xb3
ffffffffc02026f8:	f9c53503          	ld	a0,-100(a0) # ffffffffc02b5690 <pages>
ffffffffc02026fc:	071a                	slli	a4,a4,0x6
ffffffffc02026fe:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202702:	9736                	add	a4,a4,a3
ffffffffc0202704:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202706:	4118                	lw	a4,0(a0)
ffffffffc0202708:	377d                	addiw	a4,a4,-1
ffffffffc020270a:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020270c:	cb09                	beqz	a4,ffffffffc020271e <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc020270e:	0007b023          	sd	zero,0(a5) # ffffffffffe00000 <end+0x3fb4a938>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202712:	12040073          	sfence.vma	s0
}
ffffffffc0202716:	60e2                	ld	ra,24(sp)
ffffffffc0202718:	6442                	ld	s0,16(sp)
ffffffffc020271a:	6105                	addi	sp,sp,32
ffffffffc020271c:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020271e:	10002773          	csrr	a4,sstatus
ffffffffc0202722:	8b09                	andi	a4,a4,2
ffffffffc0202724:	eb19                	bnez	a4,ffffffffc020273a <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202726:	000b3717          	auipc	a4,0xb3
ffffffffc020272a:	f4273703          	ld	a4,-190(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc020272e:	4585                	li	a1,1
ffffffffc0202730:	e03e                	sd	a5,0(sp)
ffffffffc0202732:	7318                	ld	a4,32(a4)
ffffffffc0202734:	9702                	jalr	a4
    if (flag)
ffffffffc0202736:	6782                	ld	a5,0(sp)
ffffffffc0202738:	bfd9                	j	ffffffffc020270e <page_remove+0x4c>
        intr_disable();
ffffffffc020273a:	e43e                	sd	a5,8(sp)
ffffffffc020273c:	e02a                	sd	a0,0(sp)
ffffffffc020273e:	9c0fe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202742:	000b3717          	auipc	a4,0xb3
ffffffffc0202746:	f2673703          	ld	a4,-218(a4) # ffffffffc02b5668 <pmm_manager>
ffffffffc020274a:	6502                	ld	a0,0(sp)
ffffffffc020274c:	4585                	li	a1,1
ffffffffc020274e:	7318                	ld	a4,32(a4)
ffffffffc0202750:	9702                	jalr	a4
        intr_enable();
ffffffffc0202752:	9a6fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202756:	67a2                	ld	a5,8(sp)
ffffffffc0202758:	bf5d                	j	ffffffffc020270e <page_remove+0x4c>
ffffffffc020275a:	e44ff0ef          	jal	ffffffffc0201d9e <pa2page.part.0>

ffffffffc020275e <page_insert>:
{
ffffffffc020275e:	7139                	addi	sp,sp,-64
ffffffffc0202760:	f426                	sd	s1,40(sp)
ffffffffc0202762:	84b2                	mv	s1,a2
ffffffffc0202764:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202766:	4605                	li	a2,1
{
ffffffffc0202768:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020276a:	85a6                	mv	a1,s1
{
ffffffffc020276c:	fc06                	sd	ra,56(sp)
ffffffffc020276e:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202770:	ef2ff0ef          	jal	ffffffffc0201e62 <get_pte>
    if (ptep == NULL)
ffffffffc0202774:	cd61                	beqz	a0,ffffffffc020284c <page_insert+0xee>
    page->ref += 1;
ffffffffc0202776:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202778:	611c                	ld	a5,0(a0)
ffffffffc020277a:	66a2                	ld	a3,8(sp)
ffffffffc020277c:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7f27>
ffffffffc0202780:	c010                	sw	a2,0(s0)
ffffffffc0202782:	0017f613          	andi	a2,a5,1
ffffffffc0202786:	872a                	mv	a4,a0
ffffffffc0202788:	e61d                	bnez	a2,ffffffffc02027b6 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc020278a:	000b3617          	auipc	a2,0xb3
ffffffffc020278e:	f0663603          	ld	a2,-250(a2) # ffffffffc02b5690 <pages>
    return page - pages + nbase;
ffffffffc0202792:	8c11                	sub	s0,s0,a2
ffffffffc0202794:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202796:	200007b7          	lui	a5,0x20000
ffffffffc020279a:	042a                	slli	s0,s0,0xa
ffffffffc020279c:	943e                	add	s0,s0,a5
ffffffffc020279e:	8ec1                	or	a3,a3,s0
ffffffffc02027a0:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02027a4:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027a6:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02027aa:	4501                	li	a0,0
}
ffffffffc02027ac:	70e2                	ld	ra,56(sp)
ffffffffc02027ae:	7442                	ld	s0,48(sp)
ffffffffc02027b0:	74a2                	ld	s1,40(sp)
ffffffffc02027b2:	6121                	addi	sp,sp,64
ffffffffc02027b4:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02027b6:	000b3617          	auipc	a2,0xb3
ffffffffc02027ba:	ed263603          	ld	a2,-302(a2) # ffffffffc02b5688 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02027be:	078a                	slli	a5,a5,0x2
ffffffffc02027c0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02027c2:	08c7f763          	bgeu	a5,a2,ffffffffc0202850 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02027c6:	000b3617          	auipc	a2,0xb3
ffffffffc02027ca:	eca63603          	ld	a2,-310(a2) # ffffffffc02b5690 <pages>
ffffffffc02027ce:	fe000537          	lui	a0,0xfe000
ffffffffc02027d2:	079a                	slli	a5,a5,0x6
ffffffffc02027d4:	97aa                	add	a5,a5,a0
ffffffffc02027d6:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02027da:	00a40963          	beq	s0,a0,ffffffffc02027ec <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02027de:	411c                	lw	a5,0(a0)
ffffffffc02027e0:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_matrix_out_size+0x1fff4abf>
ffffffffc02027e2:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc02027e4:	c791                	beqz	a5,ffffffffc02027f0 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027e6:	12048073          	sfence.vma	s1
}
ffffffffc02027ea:	b765                	j	ffffffffc0202792 <page_insert+0x34>
ffffffffc02027ec:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc02027ee:	b755                	j	ffffffffc0202792 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02027f0:	100027f3          	csrr	a5,sstatus
ffffffffc02027f4:	8b89                	andi	a5,a5,2
ffffffffc02027f6:	e39d                	bnez	a5,ffffffffc020281c <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc02027f8:	000b3797          	auipc	a5,0xb3
ffffffffc02027fc:	e707b783          	ld	a5,-400(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc0202800:	4585                	li	a1,1
ffffffffc0202802:	e83a                	sd	a4,16(sp)
ffffffffc0202804:	739c                	ld	a5,32(a5)
ffffffffc0202806:	e436                	sd	a3,8(sp)
ffffffffc0202808:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020280a:	000b3617          	auipc	a2,0xb3
ffffffffc020280e:	e8663603          	ld	a2,-378(a2) # ffffffffc02b5690 <pages>
ffffffffc0202812:	66a2                	ld	a3,8(sp)
ffffffffc0202814:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202816:	12048073          	sfence.vma	s1
ffffffffc020281a:	bfa5                	j	ffffffffc0202792 <page_insert+0x34>
        intr_disable();
ffffffffc020281c:	ec3a                	sd	a4,24(sp)
ffffffffc020281e:	e836                	sd	a3,16(sp)
ffffffffc0202820:	e42a                	sd	a0,8(sp)
ffffffffc0202822:	8dcfe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202826:	000b3797          	auipc	a5,0xb3
ffffffffc020282a:	e427b783          	ld	a5,-446(a5) # ffffffffc02b5668 <pmm_manager>
ffffffffc020282e:	6522                	ld	a0,8(sp)
ffffffffc0202830:	4585                	li	a1,1
ffffffffc0202832:	739c                	ld	a5,32(a5)
ffffffffc0202834:	9782                	jalr	a5
        intr_enable();
ffffffffc0202836:	8c2fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020283a:	000b3617          	auipc	a2,0xb3
ffffffffc020283e:	e5663603          	ld	a2,-426(a2) # ffffffffc02b5690 <pages>
ffffffffc0202842:	6762                	ld	a4,24(sp)
ffffffffc0202844:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202846:	12048073          	sfence.vma	s1
ffffffffc020284a:	b7a1                	j	ffffffffc0202792 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc020284c:	5571                	li	a0,-4
ffffffffc020284e:	bfb9                	j	ffffffffc02027ac <page_insert+0x4e>
ffffffffc0202850:	d4eff0ef          	jal	ffffffffc0201d9e <pa2page.part.0>

ffffffffc0202854 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202854:	00005797          	auipc	a5,0x5
ffffffffc0202858:	e9478793          	addi	a5,a5,-364 # ffffffffc02076e8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020285c:	638c                	ld	a1,0(a5)
{
ffffffffc020285e:	7159                	addi	sp,sp,-112
ffffffffc0202860:	f486                	sd	ra,104(sp)
ffffffffc0202862:	e8ca                	sd	s2,80(sp)
ffffffffc0202864:	e4ce                	sd	s3,72(sp)
ffffffffc0202866:	f85a                	sd	s6,48(sp)
ffffffffc0202868:	f0a2                	sd	s0,96(sp)
ffffffffc020286a:	eca6                	sd	s1,88(sp)
ffffffffc020286c:	e0d2                	sd	s4,64(sp)
ffffffffc020286e:	fc56                	sd	s5,56(sp)
ffffffffc0202870:	f45e                	sd	s7,40(sp)
ffffffffc0202872:	f062                	sd	s8,32(sp)
ffffffffc0202874:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202876:	000b3b17          	auipc	s6,0xb3
ffffffffc020287a:	df2b0b13          	addi	s6,s6,-526 # ffffffffc02b5668 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020287e:	00004517          	auipc	a0,0x4
ffffffffc0202882:	f7250513          	addi	a0,a0,-142 # ffffffffc02067f0 <etext+0xf4c>
    pmm_manager = &default_pmm_manager;
ffffffffc0202886:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020288a:	90ffd0ef          	jal	ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc020288e:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202892:	000b3997          	auipc	s3,0xb3
ffffffffc0202896:	dee98993          	addi	s3,s3,-530 # ffffffffc02b5680 <va_pa_offset>
    pmm_manager->init();
ffffffffc020289a:	679c                	ld	a5,8(a5)
ffffffffc020289c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020289e:	57f5                	li	a5,-3
ffffffffc02028a0:	07fa                	slli	a5,a5,0x1e
ffffffffc02028a2:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02028a6:	83efe0ef          	jal	ffffffffc02008e4 <get_memory_base>
ffffffffc02028aa:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02028ac:	842fe0ef          	jal	ffffffffc02008ee <get_memory_size>
    if (mem_size == 0)
ffffffffc02028b0:	70050e63          	beqz	a0,ffffffffc0202fcc <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02028b4:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02028b6:	00004517          	auipc	a0,0x4
ffffffffc02028ba:	f7250513          	addi	a0,a0,-142 # ffffffffc0206828 <etext+0xf84>
ffffffffc02028be:	8dbfd0ef          	jal	ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02028c2:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02028c6:	864a                	mv	a2,s2
ffffffffc02028c8:	85a6                	mv	a1,s1
ffffffffc02028ca:	fff40693          	addi	a3,s0,-1
ffffffffc02028ce:	00004517          	auipc	a0,0x4
ffffffffc02028d2:	f7250513          	addi	a0,a0,-142 # ffffffffc0206840 <etext+0xf9c>
ffffffffc02028d6:	8c3fd0ef          	jal	ffffffffc0200198 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02028da:	c80007b7          	lui	a5,0xc8000
ffffffffc02028de:	8522                	mv	a0,s0
ffffffffc02028e0:	5287ed63          	bltu	a5,s0,ffffffffc0202e1a <pmm_init+0x5c6>
ffffffffc02028e4:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02028e6:	000b4617          	auipc	a2,0xb4
ffffffffc02028ea:	de160613          	addi	a2,a2,-543 # ffffffffc02b66c7 <end+0xfff>
ffffffffc02028ee:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc02028f0:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02028f2:	000b3b97          	auipc	s7,0xb3
ffffffffc02028f6:	d9eb8b93          	addi	s7,s7,-610 # ffffffffc02b5690 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02028fa:	000b3497          	auipc	s1,0xb3
ffffffffc02028fe:	d8e48493          	addi	s1,s1,-626 # ffffffffc02b5688 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202902:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202906:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202908:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020290c:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020290e:	02f50763          	beq	a0,a5,ffffffffc020293c <pmm_init+0xe8>
ffffffffc0202912:	4701                	li	a4,0
ffffffffc0202914:	4585                	li	a1,1
ffffffffc0202916:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020291a:	00671793          	slli	a5,a4,0x6
ffffffffc020291e:	97b2                	add	a5,a5,a2
ffffffffc0202920:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_matrix_out_size+0x74ac8>
ffffffffc0202922:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202926:	6088                	ld	a0,0(s1)
ffffffffc0202928:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020292a:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020292e:	00d507b3          	add	a5,a0,a3
ffffffffc0202932:	fef764e3          	bltu	a4,a5,ffffffffc020291a <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202936:	079a                	slli	a5,a5,0x6
ffffffffc0202938:	00f606b3          	add	a3,a2,a5
ffffffffc020293c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202940:	16f6eee3          	bltu	a3,a5,ffffffffc02032bc <pmm_init+0xa68>
ffffffffc0202944:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202948:	77fd                	lui	a5,0xfffff
ffffffffc020294a:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020294c:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc020294e:	4e86ed63          	bltu	a3,s0,ffffffffc0202e48 <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202952:	00004517          	auipc	a0,0x4
ffffffffc0202956:	f1650513          	addi	a0,a0,-234 # ffffffffc0206868 <etext+0xfc4>
ffffffffc020295a:	83ffd0ef          	jal	ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc020295e:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202962:	000b3917          	auipc	s2,0xb3
ffffffffc0202966:	d1690913          	addi	s2,s2,-746 # ffffffffc02b5678 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020296a:	7b9c                	ld	a5,48(a5)
ffffffffc020296c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020296e:	00004517          	auipc	a0,0x4
ffffffffc0202972:	f1250513          	addi	a0,a0,-238 # ffffffffc0206880 <etext+0xfdc>
ffffffffc0202976:	823fd0ef          	jal	ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020297a:	00008697          	auipc	a3,0x8
ffffffffc020297e:	68668693          	addi	a3,a3,1670 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202982:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202986:	c02007b7          	lui	a5,0xc0200
ffffffffc020298a:	2af6eee3          	bltu	a3,a5,ffffffffc0203446 <pmm_init+0xbf2>
ffffffffc020298e:	0009b783          	ld	a5,0(s3)
ffffffffc0202992:	8e9d                	sub	a3,a3,a5
ffffffffc0202994:	000b3797          	auipc	a5,0xb3
ffffffffc0202998:	ccd7be23          	sd	a3,-804(a5) # ffffffffc02b5670 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020299c:	100027f3          	csrr	a5,sstatus
ffffffffc02029a0:	8b89                	andi	a5,a5,2
ffffffffc02029a2:	48079963          	bnez	a5,ffffffffc0202e34 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02029a6:	000b3783          	ld	a5,0(s6)
ffffffffc02029aa:	779c                	ld	a5,40(a5)
ffffffffc02029ac:	9782                	jalr	a5
ffffffffc02029ae:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02029b0:	6098                	ld	a4,0(s1)
ffffffffc02029b2:	c80007b7          	lui	a5,0xc8000
ffffffffc02029b6:	83b1                	srli	a5,a5,0xc
ffffffffc02029b8:	66e7e663          	bltu	a5,a4,ffffffffc0203024 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02029bc:	00093503          	ld	a0,0(s2)
ffffffffc02029c0:	64050263          	beqz	a0,ffffffffc0203004 <pmm_init+0x7b0>
ffffffffc02029c4:	03451793          	slli	a5,a0,0x34
ffffffffc02029c8:	62079e63          	bnez	a5,ffffffffc0203004 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02029cc:	4601                	li	a2,0
ffffffffc02029ce:	4581                	li	a1,0
ffffffffc02029d0:	ef0ff0ef          	jal	ffffffffc02020c0 <get_page>
ffffffffc02029d4:	240519e3          	bnez	a0,ffffffffc0203426 <pmm_init+0xbd2>
ffffffffc02029d8:	100027f3          	csrr	a5,sstatus
ffffffffc02029dc:	8b89                	andi	a5,a5,2
ffffffffc02029de:	44079063          	bnez	a5,ffffffffc0202e1e <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029e2:	000b3783          	ld	a5,0(s6)
ffffffffc02029e6:	4505                	li	a0,1
ffffffffc02029e8:	6f9c                	ld	a5,24(a5)
ffffffffc02029ea:	9782                	jalr	a5
ffffffffc02029ec:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02029ee:	00093503          	ld	a0,0(s2)
ffffffffc02029f2:	4681                	li	a3,0
ffffffffc02029f4:	4601                	li	a2,0
ffffffffc02029f6:	85d2                	mv	a1,s4
ffffffffc02029f8:	d67ff0ef          	jal	ffffffffc020275e <page_insert>
ffffffffc02029fc:	280511e3          	bnez	a0,ffffffffc020347e <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202a00:	00093503          	ld	a0,0(s2)
ffffffffc0202a04:	4601                	li	a2,0
ffffffffc0202a06:	4581                	li	a1,0
ffffffffc0202a08:	c5aff0ef          	jal	ffffffffc0201e62 <get_pte>
ffffffffc0202a0c:	240509e3          	beqz	a0,ffffffffc020345e <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a10:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a12:	0017f713          	andi	a4,a5,1
ffffffffc0202a16:	58070f63          	beqz	a4,ffffffffc0202fb4 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202a1a:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a1c:	078a                	slli	a5,a5,0x2
ffffffffc0202a1e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a20:	58e7f863          	bgeu	a5,a4,ffffffffc0202fb0 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a24:	000bb683          	ld	a3,0(s7)
ffffffffc0202a28:	079a                	slli	a5,a5,0x6
ffffffffc0202a2a:	fe000637          	lui	a2,0xfe000
ffffffffc0202a2e:	97b2                	add	a5,a5,a2
ffffffffc0202a30:	97b6                	add	a5,a5,a3
ffffffffc0202a32:	14fa1ae3          	bne	s4,a5,ffffffffc0203386 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202a36:	000a2683          	lw	a3,0(s4)
ffffffffc0202a3a:	4785                	li	a5,1
ffffffffc0202a3c:	12f695e3          	bne	a3,a5,ffffffffc0203366 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202a40:	00093503          	ld	a0,0(s2)
ffffffffc0202a44:	77fd                	lui	a5,0xfffff
ffffffffc0202a46:	6114                	ld	a3,0(a0)
ffffffffc0202a48:	068a                	slli	a3,a3,0x2
ffffffffc0202a4a:	8efd                	and	a3,a3,a5
ffffffffc0202a4c:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202a50:	0ee67fe3          	bgeu	a2,a4,ffffffffc020334e <pmm_init+0xafa>
ffffffffc0202a54:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a58:	96e2                	add	a3,a3,s8
ffffffffc0202a5a:	0006ba83          	ld	s5,0(a3)
ffffffffc0202a5e:	0a8a                	slli	s5,s5,0x2
ffffffffc0202a60:	00fafab3          	and	s5,s5,a5
ffffffffc0202a64:	00cad793          	srli	a5,s5,0xc
ffffffffc0202a68:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0203334 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a6c:	4601                	li	a2,0
ffffffffc0202a6e:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a70:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a72:	bf0ff0ef          	jal	ffffffffc0201e62 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a76:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a78:	05851ee3          	bne	a0,s8,ffffffffc02032d4 <pmm_init+0xa80>
ffffffffc0202a7c:	100027f3          	csrr	a5,sstatus
ffffffffc0202a80:	8b89                	andi	a5,a5,2
ffffffffc0202a82:	3e079b63          	bnez	a5,ffffffffc0202e78 <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a86:	000b3783          	ld	a5,0(s6)
ffffffffc0202a8a:	4505                	li	a0,1
ffffffffc0202a8c:	6f9c                	ld	a5,24(a5)
ffffffffc0202a8e:	9782                	jalr	a5
ffffffffc0202a90:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202a92:	00093503          	ld	a0,0(s2)
ffffffffc0202a96:	46d1                	li	a3,20
ffffffffc0202a98:	6605                	lui	a2,0x1
ffffffffc0202a9a:	85e2                	mv	a1,s8
ffffffffc0202a9c:	cc3ff0ef          	jal	ffffffffc020275e <page_insert>
ffffffffc0202aa0:	06051ae3          	bnez	a0,ffffffffc0203314 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202aa4:	00093503          	ld	a0,0(s2)
ffffffffc0202aa8:	4601                	li	a2,0
ffffffffc0202aaa:	6585                	lui	a1,0x1
ffffffffc0202aac:	bb6ff0ef          	jal	ffffffffc0201e62 <get_pte>
ffffffffc0202ab0:	040502e3          	beqz	a0,ffffffffc02032f4 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc0202ab4:	611c                	ld	a5,0(a0)
ffffffffc0202ab6:	0107f713          	andi	a4,a5,16
ffffffffc0202aba:	7e070163          	beqz	a4,ffffffffc020329c <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc0202abe:	8b91                	andi	a5,a5,4
ffffffffc0202ac0:	7a078e63          	beqz	a5,ffffffffc020327c <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202ac4:	00093503          	ld	a0,0(s2)
ffffffffc0202ac8:	611c                	ld	a5,0(a0)
ffffffffc0202aca:	8bc1                	andi	a5,a5,16
ffffffffc0202acc:	78078863          	beqz	a5,ffffffffc020325c <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc0202ad0:	000c2703          	lw	a4,0(s8)
ffffffffc0202ad4:	4785                	li	a5,1
ffffffffc0202ad6:	76f71363          	bne	a4,a5,ffffffffc020323c <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202ada:	4681                	li	a3,0
ffffffffc0202adc:	6605                	lui	a2,0x1
ffffffffc0202ade:	85d2                	mv	a1,s4
ffffffffc0202ae0:	c7fff0ef          	jal	ffffffffc020275e <page_insert>
ffffffffc0202ae4:	72051c63          	bnez	a0,ffffffffc020321c <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc0202ae8:	000a2703          	lw	a4,0(s4)
ffffffffc0202aec:	4789                	li	a5,2
ffffffffc0202aee:	70f71763          	bne	a4,a5,ffffffffc02031fc <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202af2:	000c2783          	lw	a5,0(s8)
ffffffffc0202af6:	6e079363          	bnez	a5,ffffffffc02031dc <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202afa:	00093503          	ld	a0,0(s2)
ffffffffc0202afe:	4601                	li	a2,0
ffffffffc0202b00:	6585                	lui	a1,0x1
ffffffffc0202b02:	b60ff0ef          	jal	ffffffffc0201e62 <get_pte>
ffffffffc0202b06:	6a050b63          	beqz	a0,ffffffffc02031bc <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202b0a:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202b0c:	00177793          	andi	a5,a4,1
ffffffffc0202b10:	4a078263          	beqz	a5,ffffffffc0202fb4 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202b14:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202b16:	00271793          	slli	a5,a4,0x2
ffffffffc0202b1a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b1c:	48d7fa63          	bgeu	a5,a3,ffffffffc0202fb0 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b20:	000bb683          	ld	a3,0(s7)
ffffffffc0202b24:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202b28:	97d6                	add	a5,a5,s5
ffffffffc0202b2a:	079a                	slli	a5,a5,0x6
ffffffffc0202b2c:	97b6                	add	a5,a5,a3
ffffffffc0202b2e:	66fa1763          	bne	s4,a5,ffffffffc020319c <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202b32:	8b41                	andi	a4,a4,16
ffffffffc0202b34:	64071463          	bnez	a4,ffffffffc020317c <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202b38:	00093503          	ld	a0,0(s2)
ffffffffc0202b3c:	4581                	li	a1,0
ffffffffc0202b3e:	b85ff0ef          	jal	ffffffffc02026c2 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202b42:	000a2c83          	lw	s9,0(s4)
ffffffffc0202b46:	4785                	li	a5,1
ffffffffc0202b48:	60fc9a63          	bne	s9,a5,ffffffffc020315c <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202b4c:	000c2783          	lw	a5,0(s8)
ffffffffc0202b50:	5e079663          	bnez	a5,ffffffffc020313c <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202b54:	00093503          	ld	a0,0(s2)
ffffffffc0202b58:	6585                	lui	a1,0x1
ffffffffc0202b5a:	b69ff0ef          	jal	ffffffffc02026c2 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202b5e:	000a2783          	lw	a5,0(s4)
ffffffffc0202b62:	52079d63          	bnez	a5,ffffffffc020309c <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202b66:	000c2783          	lw	a5,0(s8)
ffffffffc0202b6a:	50079963          	bnez	a5,ffffffffc020307c <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202b6e:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b72:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b74:	000a3783          	ld	a5,0(s4)
ffffffffc0202b78:	078a                	slli	a5,a5,0x2
ffffffffc0202b7a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b7c:	42e7fa63          	bgeu	a5,a4,ffffffffc0202fb0 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b80:	000bb503          	ld	a0,0(s7)
ffffffffc0202b84:	97d6                	add	a5,a5,s5
ffffffffc0202b86:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202b88:	00f506b3          	add	a3,a0,a5
ffffffffc0202b8c:	4294                	lw	a3,0(a3)
ffffffffc0202b8e:	4d969763          	bne	a3,s9,ffffffffc020305c <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202b92:	8799                	srai	a5,a5,0x6
ffffffffc0202b94:	00080637          	lui	a2,0x80
ffffffffc0202b98:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b9a:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202b9e:	4ae7f363          	bgeu	a5,a4,ffffffffc0203044 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202ba2:	0009b783          	ld	a5,0(s3)
ffffffffc0202ba6:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ba8:	639c                	ld	a5,0(a5)
ffffffffc0202baa:	078a                	slli	a5,a5,0x2
ffffffffc0202bac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bae:	40e7f163          	bgeu	a5,a4,ffffffffc0202fb0 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bb2:	8f91                	sub	a5,a5,a2
ffffffffc0202bb4:	079a                	slli	a5,a5,0x6
ffffffffc0202bb6:	953e                	add	a0,a0,a5
ffffffffc0202bb8:	100027f3          	csrr	a5,sstatus
ffffffffc0202bbc:	8b89                	andi	a5,a5,2
ffffffffc0202bbe:	30079863          	bnez	a5,ffffffffc0202ece <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202bc2:	000b3783          	ld	a5,0(s6)
ffffffffc0202bc6:	4585                	li	a1,1
ffffffffc0202bc8:	739c                	ld	a5,32(a5)
ffffffffc0202bca:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bcc:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202bd0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bd2:	078a                	slli	a5,a5,0x2
ffffffffc0202bd4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bd6:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202fb0 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bda:	000bb503          	ld	a0,0(s7)
ffffffffc0202bde:	fe000737          	lui	a4,0xfe000
ffffffffc0202be2:	079a                	slli	a5,a5,0x6
ffffffffc0202be4:	97ba                	add	a5,a5,a4
ffffffffc0202be6:	953e                	add	a0,a0,a5
ffffffffc0202be8:	100027f3          	csrr	a5,sstatus
ffffffffc0202bec:	8b89                	andi	a5,a5,2
ffffffffc0202bee:	2c079463          	bnez	a5,ffffffffc0202eb6 <pmm_init+0x662>
ffffffffc0202bf2:	000b3783          	ld	a5,0(s6)
ffffffffc0202bf6:	4585                	li	a1,1
ffffffffc0202bf8:	739c                	ld	a5,32(a5)
ffffffffc0202bfa:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202bfc:	00093783          	ld	a5,0(s2)
ffffffffc0202c00:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd49938>
    asm volatile("sfence.vma");
ffffffffc0202c04:	12000073          	sfence.vma
ffffffffc0202c08:	100027f3          	csrr	a5,sstatus
ffffffffc0202c0c:	8b89                	andi	a5,a5,2
ffffffffc0202c0e:	28079a63          	bnez	a5,ffffffffc0202ea2 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c12:	000b3783          	ld	a5,0(s6)
ffffffffc0202c16:	779c                	ld	a5,40(a5)
ffffffffc0202c18:	9782                	jalr	a5
ffffffffc0202c1a:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c1c:	4d441063          	bne	s0,s4,ffffffffc02030dc <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202c20:	00004517          	auipc	a0,0x4
ffffffffc0202c24:	f8850513          	addi	a0,a0,-120 # ffffffffc0206ba8 <etext+0x1304>
ffffffffc0202c28:	d70fd0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc0202c2c:	100027f3          	csrr	a5,sstatus
ffffffffc0202c30:	8b89                	andi	a5,a5,2
ffffffffc0202c32:	24079e63          	bnez	a5,ffffffffc0202e8e <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c36:	000b3783          	ld	a5,0(s6)
ffffffffc0202c3a:	779c                	ld	a5,40(a5)
ffffffffc0202c3c:	9782                	jalr	a5
ffffffffc0202c3e:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c40:	609c                	ld	a5,0(s1)
ffffffffc0202c42:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c46:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c48:	00c79713          	slli	a4,a5,0xc
ffffffffc0202c4c:	6a85                	lui	s5,0x1
ffffffffc0202c4e:	02e47c63          	bgeu	s0,a4,ffffffffc0202c86 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202c52:	00c45713          	srli	a4,s0,0xc
ffffffffc0202c56:	30f77063          	bgeu	a4,a5,ffffffffc0202f56 <pmm_init+0x702>
ffffffffc0202c5a:	0009b583          	ld	a1,0(s3)
ffffffffc0202c5e:	00093503          	ld	a0,0(s2)
ffffffffc0202c62:	4601                	li	a2,0
ffffffffc0202c64:	95a2                	add	a1,a1,s0
ffffffffc0202c66:	9fcff0ef          	jal	ffffffffc0201e62 <get_pte>
ffffffffc0202c6a:	32050363          	beqz	a0,ffffffffc0202f90 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c6e:	611c                	ld	a5,0(a0)
ffffffffc0202c70:	078a                	slli	a5,a5,0x2
ffffffffc0202c72:	0147f7b3          	and	a5,a5,s4
ffffffffc0202c76:	2e879d63          	bne	a5,s0,ffffffffc0202f70 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c7a:	609c                	ld	a5,0(s1)
ffffffffc0202c7c:	9456                	add	s0,s0,s5
ffffffffc0202c7e:	00c79713          	slli	a4,a5,0xc
ffffffffc0202c82:	fce468e3          	bltu	s0,a4,ffffffffc0202c52 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202c86:	00093783          	ld	a5,0(s2)
ffffffffc0202c8a:	639c                	ld	a5,0(a5)
ffffffffc0202c8c:	42079863          	bnez	a5,ffffffffc02030bc <pmm_init+0x868>
ffffffffc0202c90:	100027f3          	csrr	a5,sstatus
ffffffffc0202c94:	8b89                	andi	a5,a5,2
ffffffffc0202c96:	24079863          	bnez	a5,ffffffffc0202ee6 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c9a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c9e:	4505                	li	a0,1
ffffffffc0202ca0:	6f9c                	ld	a5,24(a5)
ffffffffc0202ca2:	9782                	jalr	a5
ffffffffc0202ca4:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202ca6:	00093503          	ld	a0,0(s2)
ffffffffc0202caa:	4699                	li	a3,6
ffffffffc0202cac:	10000613          	li	a2,256
ffffffffc0202cb0:	85a2                	mv	a1,s0
ffffffffc0202cb2:	aadff0ef          	jal	ffffffffc020275e <page_insert>
ffffffffc0202cb6:	46051363          	bnez	a0,ffffffffc020311c <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202cba:	4018                	lw	a4,0(s0)
ffffffffc0202cbc:	4785                	li	a5,1
ffffffffc0202cbe:	42f71f63          	bne	a4,a5,ffffffffc02030fc <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202cc2:	00093503          	ld	a0,0(s2)
ffffffffc0202cc6:	6605                	lui	a2,0x1
ffffffffc0202cc8:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7e28>
ffffffffc0202ccc:	4699                	li	a3,6
ffffffffc0202cce:	85a2                	mv	a1,s0
ffffffffc0202cd0:	a8fff0ef          	jal	ffffffffc020275e <page_insert>
ffffffffc0202cd4:	72051963          	bnez	a0,ffffffffc0203406 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202cd8:	4018                	lw	a4,0(s0)
ffffffffc0202cda:	4789                	li	a5,2
ffffffffc0202cdc:	70f71563          	bne	a4,a5,ffffffffc02033e6 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202ce0:	00004597          	auipc	a1,0x4
ffffffffc0202ce4:	01058593          	addi	a1,a1,16 # ffffffffc0206cf0 <etext+0x144c>
ffffffffc0202ce8:	10000513          	li	a0,256
ffffffffc0202cec:	30f020ef          	jal	ffffffffc02057fa <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cf0:	6585                	lui	a1,0x1
ffffffffc0202cf2:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7e28>
ffffffffc0202cf6:	10000513          	li	a0,256
ffffffffc0202cfa:	313020ef          	jal	ffffffffc020580c <strcmp>
ffffffffc0202cfe:	6c051463          	bnez	a0,ffffffffc02033c6 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202d02:	000bb683          	ld	a3,0(s7)
ffffffffc0202d06:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202d0a:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202d0c:	40d406b3          	sub	a3,s0,a3
ffffffffc0202d10:	8699                	srai	a3,a3,0x6
ffffffffc0202d12:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202d14:	00c69793          	slli	a5,a3,0xc
ffffffffc0202d18:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202d1a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202d1c:	32e7f463          	bgeu	a5,a4,ffffffffc0203044 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202d20:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202d24:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202d28:	97b6                	add	a5,a5,a3
ffffffffc0202d2a:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_matrix_out_size+0x74bc0>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202d2e:	299020ef          	jal	ffffffffc02057c6 <strlen>
ffffffffc0202d32:	66051a63          	bnez	a0,ffffffffc02033a6 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202d36:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202d3a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d3c:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd49938>
ffffffffc0202d40:	078a                	slli	a5,a5,0x2
ffffffffc0202d42:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d44:	26e7f663          	bgeu	a5,a4,ffffffffc0202fb0 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202d48:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202d4c:	2ee7fc63          	bgeu	a5,a4,ffffffffc0203044 <pmm_init+0x7f0>
ffffffffc0202d50:	0009b783          	ld	a5,0(s3)
ffffffffc0202d54:	00f689b3          	add	s3,a3,a5
ffffffffc0202d58:	100027f3          	csrr	a5,sstatus
ffffffffc0202d5c:	8b89                	andi	a5,a5,2
ffffffffc0202d5e:	1e079163          	bnez	a5,ffffffffc0202f40 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202d62:	000b3783          	ld	a5,0(s6)
ffffffffc0202d66:	8522                	mv	a0,s0
ffffffffc0202d68:	4585                	li	a1,1
ffffffffc0202d6a:	739c                	ld	a5,32(a5)
ffffffffc0202d6c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d6e:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202d72:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d74:	078a                	slli	a5,a5,0x2
ffffffffc0202d76:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d78:	22e7fc63          	bgeu	a5,a4,ffffffffc0202fb0 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d7c:	000bb503          	ld	a0,0(s7)
ffffffffc0202d80:	fe000737          	lui	a4,0xfe000
ffffffffc0202d84:	079a                	slli	a5,a5,0x6
ffffffffc0202d86:	97ba                	add	a5,a5,a4
ffffffffc0202d88:	953e                	add	a0,a0,a5
ffffffffc0202d8a:	100027f3          	csrr	a5,sstatus
ffffffffc0202d8e:	8b89                	andi	a5,a5,2
ffffffffc0202d90:	18079c63          	bnez	a5,ffffffffc0202f28 <pmm_init+0x6d4>
ffffffffc0202d94:	000b3783          	ld	a5,0(s6)
ffffffffc0202d98:	4585                	li	a1,1
ffffffffc0202d9a:	739c                	ld	a5,32(a5)
ffffffffc0202d9c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d9e:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202da2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202da4:	078a                	slli	a5,a5,0x2
ffffffffc0202da6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202da8:	20e7f463          	bgeu	a5,a4,ffffffffc0202fb0 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202dac:	000bb503          	ld	a0,0(s7)
ffffffffc0202db0:	fe000737          	lui	a4,0xfe000
ffffffffc0202db4:	079a                	slli	a5,a5,0x6
ffffffffc0202db6:	97ba                	add	a5,a5,a4
ffffffffc0202db8:	953e                	add	a0,a0,a5
ffffffffc0202dba:	100027f3          	csrr	a5,sstatus
ffffffffc0202dbe:	8b89                	andi	a5,a5,2
ffffffffc0202dc0:	14079863          	bnez	a5,ffffffffc0202f10 <pmm_init+0x6bc>
ffffffffc0202dc4:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc8:	4585                	li	a1,1
ffffffffc0202dca:	739c                	ld	a5,32(a5)
ffffffffc0202dcc:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202dce:	00093783          	ld	a5,0(s2)
ffffffffc0202dd2:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202dd6:	12000073          	sfence.vma
ffffffffc0202dda:	100027f3          	csrr	a5,sstatus
ffffffffc0202dde:	8b89                	andi	a5,a5,2
ffffffffc0202de0:	10079e63          	bnez	a5,ffffffffc0202efc <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202de4:	000b3783          	ld	a5,0(s6)
ffffffffc0202de8:	779c                	ld	a5,40(a5)
ffffffffc0202dea:	9782                	jalr	a5
ffffffffc0202dec:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202dee:	1e8c1b63          	bne	s8,s0,ffffffffc0202fe4 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202df2:	00004517          	auipc	a0,0x4
ffffffffc0202df6:	f7650513          	addi	a0,a0,-138 # ffffffffc0206d68 <etext+0x14c4>
ffffffffc0202dfa:	b9efd0ef          	jal	ffffffffc0200198 <cprintf>
}
ffffffffc0202dfe:	7406                	ld	s0,96(sp)
ffffffffc0202e00:	70a6                	ld	ra,104(sp)
ffffffffc0202e02:	64e6                	ld	s1,88(sp)
ffffffffc0202e04:	6946                	ld	s2,80(sp)
ffffffffc0202e06:	69a6                	ld	s3,72(sp)
ffffffffc0202e08:	6a06                	ld	s4,64(sp)
ffffffffc0202e0a:	7ae2                	ld	s5,56(sp)
ffffffffc0202e0c:	7b42                	ld	s6,48(sp)
ffffffffc0202e0e:	7ba2                	ld	s7,40(sp)
ffffffffc0202e10:	7c02                	ld	s8,32(sp)
ffffffffc0202e12:	6ce2                	ld	s9,24(sp)
ffffffffc0202e14:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202e16:	dbffe06f          	j	ffffffffc0201bd4 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202e1a:	853e                	mv	a0,a5
ffffffffc0202e1c:	b4e1                	j	ffffffffc02028e4 <pmm_init+0x90>
        intr_disable();
ffffffffc0202e1e:	ae1fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e22:	000b3783          	ld	a5,0(s6)
ffffffffc0202e26:	4505                	li	a0,1
ffffffffc0202e28:	6f9c                	ld	a5,24(a5)
ffffffffc0202e2a:	9782                	jalr	a5
ffffffffc0202e2c:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e2e:	acbfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202e32:	be75                	j	ffffffffc02029ee <pmm_init+0x19a>
        intr_disable();
ffffffffc0202e34:	acbfd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e38:	000b3783          	ld	a5,0(s6)
ffffffffc0202e3c:	779c                	ld	a5,40(a5)
ffffffffc0202e3e:	9782                	jalr	a5
ffffffffc0202e40:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e42:	ab7fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202e46:	b6ad                	j	ffffffffc02029b0 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202e48:	6705                	lui	a4,0x1
ffffffffc0202e4a:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7f29>
ffffffffc0202e4c:	96ba                	add	a3,a3,a4
ffffffffc0202e4e:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202e50:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202e54:	14a77e63          	bgeu	a4,a0,ffffffffc0202fb0 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202e58:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202e5c:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202e5e:	071a                	slli	a4,a4,0x6
ffffffffc0202e60:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202e64:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202e66:	6a9c                	ld	a5,16(a3)
ffffffffc0202e68:	00c45593          	srli	a1,s0,0xc
ffffffffc0202e6c:	00e60533          	add	a0,a2,a4
ffffffffc0202e70:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202e72:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202e76:	bcf1                	j	ffffffffc0202952 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202e78:	a87fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e7c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e80:	4505                	li	a0,1
ffffffffc0202e82:	6f9c                	ld	a5,24(a5)
ffffffffc0202e84:	9782                	jalr	a5
ffffffffc0202e86:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e88:	a71fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202e8c:	b119                	j	ffffffffc0202a92 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202e8e:	a71fd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e92:	000b3783          	ld	a5,0(s6)
ffffffffc0202e96:	779c                	ld	a5,40(a5)
ffffffffc0202e98:	9782                	jalr	a5
ffffffffc0202e9a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e9c:	a5dfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202ea0:	b345                	j	ffffffffc0202c40 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202ea2:	a5dfd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202ea6:	000b3783          	ld	a5,0(s6)
ffffffffc0202eaa:	779c                	ld	a5,40(a5)
ffffffffc0202eac:	9782                	jalr	a5
ffffffffc0202eae:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202eb0:	a49fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202eb4:	b3a5                	j	ffffffffc0202c1c <pmm_init+0x3c8>
ffffffffc0202eb6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202eb8:	a47fd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ebc:	000b3783          	ld	a5,0(s6)
ffffffffc0202ec0:	6522                	ld	a0,8(sp)
ffffffffc0202ec2:	4585                	li	a1,1
ffffffffc0202ec4:	739c                	ld	a5,32(a5)
ffffffffc0202ec6:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ec8:	a31fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202ecc:	bb05                	j	ffffffffc0202bfc <pmm_init+0x3a8>
ffffffffc0202ece:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ed0:	a2ffd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202ed4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ed8:	6522                	ld	a0,8(sp)
ffffffffc0202eda:	4585                	li	a1,1
ffffffffc0202edc:	739c                	ld	a5,32(a5)
ffffffffc0202ede:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ee0:	a19fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202ee4:	b1e5                	j	ffffffffc0202bcc <pmm_init+0x378>
        intr_disable();
ffffffffc0202ee6:	a19fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202eea:	000b3783          	ld	a5,0(s6)
ffffffffc0202eee:	4505                	li	a0,1
ffffffffc0202ef0:	6f9c                	ld	a5,24(a5)
ffffffffc0202ef2:	9782                	jalr	a5
ffffffffc0202ef4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202ef6:	a03fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202efa:	b375                	j	ffffffffc0202ca6 <pmm_init+0x452>
        intr_disable();
ffffffffc0202efc:	a03fd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f00:	000b3783          	ld	a5,0(s6)
ffffffffc0202f04:	779c                	ld	a5,40(a5)
ffffffffc0202f06:	9782                	jalr	a5
ffffffffc0202f08:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202f0a:	9effd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202f0e:	b5c5                	j	ffffffffc0202dee <pmm_init+0x59a>
ffffffffc0202f10:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202f12:	9edfd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202f16:	000b3783          	ld	a5,0(s6)
ffffffffc0202f1a:	6522                	ld	a0,8(sp)
ffffffffc0202f1c:	4585                	li	a1,1
ffffffffc0202f1e:	739c                	ld	a5,32(a5)
ffffffffc0202f20:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f22:	9d7fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202f26:	b565                	j	ffffffffc0202dce <pmm_init+0x57a>
ffffffffc0202f28:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202f2a:	9d5fd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202f2e:	000b3783          	ld	a5,0(s6)
ffffffffc0202f32:	6522                	ld	a0,8(sp)
ffffffffc0202f34:	4585                	li	a1,1
ffffffffc0202f36:	739c                	ld	a5,32(a5)
ffffffffc0202f38:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f3a:	9bffd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202f3e:	b585                	j	ffffffffc0202d9e <pmm_init+0x54a>
        intr_disable();
ffffffffc0202f40:	9bffd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202f44:	000b3783          	ld	a5,0(s6)
ffffffffc0202f48:	8522                	mv	a0,s0
ffffffffc0202f4a:	4585                	li	a1,1
ffffffffc0202f4c:	739c                	ld	a5,32(a5)
ffffffffc0202f4e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f50:	9a9fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202f54:	bd29                	j	ffffffffc0202d6e <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f56:	86a2                	mv	a3,s0
ffffffffc0202f58:	00003617          	auipc	a2,0x3
ffffffffc0202f5c:	70860613          	addi	a2,a2,1800 # ffffffffc0206660 <etext+0xdbc>
ffffffffc0202f60:	24d00593          	li	a1,589
ffffffffc0202f64:	00003517          	auipc	a0,0x3
ffffffffc0202f68:	7ec50513          	addi	a0,a0,2028 # ffffffffc0206750 <etext+0xeac>
ffffffffc0202f6c:	cdefd0ef          	jal	ffffffffc020044a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f70:	00004697          	auipc	a3,0x4
ffffffffc0202f74:	c9868693          	addi	a3,a3,-872 # ffffffffc0206c08 <etext+0x1364>
ffffffffc0202f78:	00003617          	auipc	a2,0x3
ffffffffc0202f7c:	33860613          	addi	a2,a2,824 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0202f80:	24e00593          	li	a1,590
ffffffffc0202f84:	00003517          	auipc	a0,0x3
ffffffffc0202f88:	7cc50513          	addi	a0,a0,1996 # ffffffffc0206750 <etext+0xeac>
ffffffffc0202f8c:	cbefd0ef          	jal	ffffffffc020044a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f90:	00004697          	auipc	a3,0x4
ffffffffc0202f94:	c3868693          	addi	a3,a3,-968 # ffffffffc0206bc8 <etext+0x1324>
ffffffffc0202f98:	00003617          	auipc	a2,0x3
ffffffffc0202f9c:	31860613          	addi	a2,a2,792 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0202fa0:	24d00593          	li	a1,589
ffffffffc0202fa4:	00003517          	auipc	a0,0x3
ffffffffc0202fa8:	7ac50513          	addi	a0,a0,1964 # ffffffffc0206750 <etext+0xeac>
ffffffffc0202fac:	c9efd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0202fb0:	deffe0ef          	jal	ffffffffc0201d9e <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202fb4:	00003617          	auipc	a2,0x3
ffffffffc0202fb8:	7f460613          	addi	a2,a2,2036 # ffffffffc02067a8 <etext+0xf04>
ffffffffc0202fbc:	07f00593          	li	a1,127
ffffffffc0202fc0:	00003517          	auipc	a0,0x3
ffffffffc0202fc4:	6c850513          	addi	a0,a0,1736 # ffffffffc0206688 <etext+0xde4>
ffffffffc0202fc8:	c82fd0ef          	jal	ffffffffc020044a <__panic>
        panic("DTB memory info not available");
ffffffffc0202fcc:	00004617          	auipc	a2,0x4
ffffffffc0202fd0:	83c60613          	addi	a2,a2,-1988 # ffffffffc0206808 <etext+0xf64>
ffffffffc0202fd4:	06500593          	li	a1,101
ffffffffc0202fd8:	00003517          	auipc	a0,0x3
ffffffffc0202fdc:	77850513          	addi	a0,a0,1912 # ffffffffc0206750 <etext+0xeac>
ffffffffc0202fe0:	c6afd0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202fe4:	00004697          	auipc	a3,0x4
ffffffffc0202fe8:	b9c68693          	addi	a3,a3,-1124 # ffffffffc0206b80 <etext+0x12dc>
ffffffffc0202fec:	00003617          	auipc	a2,0x3
ffffffffc0202ff0:	2c460613          	addi	a2,a2,708 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0202ff4:	26800593          	li	a1,616
ffffffffc0202ff8:	00003517          	auipc	a0,0x3
ffffffffc0202ffc:	75850513          	addi	a0,a0,1880 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203000:	c4afd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0203004:	00004697          	auipc	a3,0x4
ffffffffc0203008:	8bc68693          	addi	a3,a3,-1860 # ffffffffc02068c0 <etext+0x101c>
ffffffffc020300c:	00003617          	auipc	a2,0x3
ffffffffc0203010:	2a460613          	addi	a2,a2,676 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203014:	20f00593          	li	a1,527
ffffffffc0203018:	00003517          	auipc	a0,0x3
ffffffffc020301c:	73850513          	addi	a0,a0,1848 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203020:	c2afd0ef          	jal	ffffffffc020044a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203024:	00004697          	auipc	a3,0x4
ffffffffc0203028:	87c68693          	addi	a3,a3,-1924 # ffffffffc02068a0 <etext+0xffc>
ffffffffc020302c:	00003617          	auipc	a2,0x3
ffffffffc0203030:	28460613          	addi	a2,a2,644 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203034:	20e00593          	li	a1,526
ffffffffc0203038:	00003517          	auipc	a0,0x3
ffffffffc020303c:	71850513          	addi	a0,a0,1816 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203040:	c0afd0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc0203044:	00003617          	auipc	a2,0x3
ffffffffc0203048:	61c60613          	addi	a2,a2,1564 # ffffffffc0206660 <etext+0xdbc>
ffffffffc020304c:	07100593          	li	a1,113
ffffffffc0203050:	00003517          	auipc	a0,0x3
ffffffffc0203054:	63850513          	addi	a0,a0,1592 # ffffffffc0206688 <etext+0xde4>
ffffffffc0203058:	bf2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020305c:	00004697          	auipc	a3,0x4
ffffffffc0203060:	af468693          	addi	a3,a3,-1292 # ffffffffc0206b50 <etext+0x12ac>
ffffffffc0203064:	00003617          	auipc	a2,0x3
ffffffffc0203068:	24c60613          	addi	a2,a2,588 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020306c:	23600593          	li	a1,566
ffffffffc0203070:	00003517          	auipc	a0,0x3
ffffffffc0203074:	6e050513          	addi	a0,a0,1760 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203078:	bd2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020307c:	00004697          	auipc	a3,0x4
ffffffffc0203080:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0206b08 <etext+0x1264>
ffffffffc0203084:	00003617          	auipc	a2,0x3
ffffffffc0203088:	22c60613          	addi	a2,a2,556 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020308c:	23400593          	li	a1,564
ffffffffc0203090:	00003517          	auipc	a0,0x3
ffffffffc0203094:	6c050513          	addi	a0,a0,1728 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203098:	bb2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020309c:	00004697          	auipc	a3,0x4
ffffffffc02030a0:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0206b38 <etext+0x1294>
ffffffffc02030a4:	00003617          	auipc	a2,0x3
ffffffffc02030a8:	20c60613          	addi	a2,a2,524 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02030ac:	23300593          	li	a1,563
ffffffffc02030b0:	00003517          	auipc	a0,0x3
ffffffffc02030b4:	6a050513          	addi	a0,a0,1696 # ffffffffc0206750 <etext+0xeac>
ffffffffc02030b8:	b92fd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02030bc:	00004697          	auipc	a3,0x4
ffffffffc02030c0:	b6468693          	addi	a3,a3,-1180 # ffffffffc0206c20 <etext+0x137c>
ffffffffc02030c4:	00003617          	auipc	a2,0x3
ffffffffc02030c8:	1ec60613          	addi	a2,a2,492 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02030cc:	25100593          	li	a1,593
ffffffffc02030d0:	00003517          	auipc	a0,0x3
ffffffffc02030d4:	68050513          	addi	a0,a0,1664 # ffffffffc0206750 <etext+0xeac>
ffffffffc02030d8:	b72fd0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02030dc:	00004697          	auipc	a3,0x4
ffffffffc02030e0:	aa468693          	addi	a3,a3,-1372 # ffffffffc0206b80 <etext+0x12dc>
ffffffffc02030e4:	00003617          	auipc	a2,0x3
ffffffffc02030e8:	1cc60613          	addi	a2,a2,460 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02030ec:	23e00593          	li	a1,574
ffffffffc02030f0:	00003517          	auipc	a0,0x3
ffffffffc02030f4:	66050513          	addi	a0,a0,1632 # ffffffffc0206750 <etext+0xeac>
ffffffffc02030f8:	b52fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p) == 1);
ffffffffc02030fc:	00004697          	auipc	a3,0x4
ffffffffc0203100:	b7c68693          	addi	a3,a3,-1156 # ffffffffc0206c78 <etext+0x13d4>
ffffffffc0203104:	00003617          	auipc	a2,0x3
ffffffffc0203108:	1ac60613          	addi	a2,a2,428 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020310c:	25600593          	li	a1,598
ffffffffc0203110:	00003517          	auipc	a0,0x3
ffffffffc0203114:	64050513          	addi	a0,a0,1600 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203118:	b32fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020311c:	00004697          	auipc	a3,0x4
ffffffffc0203120:	b1c68693          	addi	a3,a3,-1252 # ffffffffc0206c38 <etext+0x1394>
ffffffffc0203124:	00003617          	auipc	a2,0x3
ffffffffc0203128:	18c60613          	addi	a2,a2,396 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020312c:	25500593          	li	a1,597
ffffffffc0203130:	00003517          	auipc	a0,0x3
ffffffffc0203134:	62050513          	addi	a0,a0,1568 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203138:	b12fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020313c:	00004697          	auipc	a3,0x4
ffffffffc0203140:	9cc68693          	addi	a3,a3,-1588 # ffffffffc0206b08 <etext+0x1264>
ffffffffc0203144:	00003617          	auipc	a2,0x3
ffffffffc0203148:	16c60613          	addi	a2,a2,364 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020314c:	23000593          	li	a1,560
ffffffffc0203150:	00003517          	auipc	a0,0x3
ffffffffc0203154:	60050513          	addi	a0,a0,1536 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203158:	af2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020315c:	00004697          	auipc	a3,0x4
ffffffffc0203160:	84c68693          	addi	a3,a3,-1972 # ffffffffc02069a8 <etext+0x1104>
ffffffffc0203164:	00003617          	auipc	a2,0x3
ffffffffc0203168:	14c60613          	addi	a2,a2,332 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020316c:	22f00593          	li	a1,559
ffffffffc0203170:	00003517          	auipc	a0,0x3
ffffffffc0203174:	5e050513          	addi	a0,a0,1504 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203178:	ad2fd0ef          	jal	ffffffffc020044a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020317c:	00004697          	auipc	a3,0x4
ffffffffc0203180:	9a468693          	addi	a3,a3,-1628 # ffffffffc0206b20 <etext+0x127c>
ffffffffc0203184:	00003617          	auipc	a2,0x3
ffffffffc0203188:	12c60613          	addi	a2,a2,300 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020318c:	22c00593          	li	a1,556
ffffffffc0203190:	00003517          	auipc	a0,0x3
ffffffffc0203194:	5c050513          	addi	a0,a0,1472 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203198:	ab2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020319c:	00003697          	auipc	a3,0x3
ffffffffc02031a0:	7f468693          	addi	a3,a3,2036 # ffffffffc0206990 <etext+0x10ec>
ffffffffc02031a4:	00003617          	auipc	a2,0x3
ffffffffc02031a8:	10c60613          	addi	a2,a2,268 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02031ac:	22b00593          	li	a1,555
ffffffffc02031b0:	00003517          	auipc	a0,0x3
ffffffffc02031b4:	5a050513          	addi	a0,a0,1440 # ffffffffc0206750 <etext+0xeac>
ffffffffc02031b8:	a92fd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02031bc:	00004697          	auipc	a3,0x4
ffffffffc02031c0:	87468693          	addi	a3,a3,-1932 # ffffffffc0206a30 <etext+0x118c>
ffffffffc02031c4:	00003617          	auipc	a2,0x3
ffffffffc02031c8:	0ec60613          	addi	a2,a2,236 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02031cc:	22a00593          	li	a1,554
ffffffffc02031d0:	00003517          	auipc	a0,0x3
ffffffffc02031d4:	58050513          	addi	a0,a0,1408 # ffffffffc0206750 <etext+0xeac>
ffffffffc02031d8:	a72fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02031dc:	00004697          	auipc	a3,0x4
ffffffffc02031e0:	92c68693          	addi	a3,a3,-1748 # ffffffffc0206b08 <etext+0x1264>
ffffffffc02031e4:	00003617          	auipc	a2,0x3
ffffffffc02031e8:	0cc60613          	addi	a2,a2,204 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02031ec:	22900593          	li	a1,553
ffffffffc02031f0:	00003517          	auipc	a0,0x3
ffffffffc02031f4:	56050513          	addi	a0,a0,1376 # ffffffffc0206750 <etext+0xeac>
ffffffffc02031f8:	a52fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02031fc:	00004697          	auipc	a3,0x4
ffffffffc0203200:	8f468693          	addi	a3,a3,-1804 # ffffffffc0206af0 <etext+0x124c>
ffffffffc0203204:	00003617          	auipc	a2,0x3
ffffffffc0203208:	0ac60613          	addi	a2,a2,172 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020320c:	22800593          	li	a1,552
ffffffffc0203210:	00003517          	auipc	a0,0x3
ffffffffc0203214:	54050513          	addi	a0,a0,1344 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203218:	a32fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc020321c:	00004697          	auipc	a3,0x4
ffffffffc0203220:	8a468693          	addi	a3,a3,-1884 # ffffffffc0206ac0 <etext+0x121c>
ffffffffc0203224:	00003617          	auipc	a2,0x3
ffffffffc0203228:	08c60613          	addi	a2,a2,140 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020322c:	22700593          	li	a1,551
ffffffffc0203230:	00003517          	auipc	a0,0x3
ffffffffc0203234:	52050513          	addi	a0,a0,1312 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203238:	a12fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020323c:	00004697          	auipc	a3,0x4
ffffffffc0203240:	86c68693          	addi	a3,a3,-1940 # ffffffffc0206aa8 <etext+0x1204>
ffffffffc0203244:	00003617          	auipc	a2,0x3
ffffffffc0203248:	06c60613          	addi	a2,a2,108 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020324c:	22500593          	li	a1,549
ffffffffc0203250:	00003517          	auipc	a0,0x3
ffffffffc0203254:	50050513          	addi	a0,a0,1280 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203258:	9f2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020325c:	00004697          	auipc	a3,0x4
ffffffffc0203260:	82c68693          	addi	a3,a3,-2004 # ffffffffc0206a88 <etext+0x11e4>
ffffffffc0203264:	00003617          	auipc	a2,0x3
ffffffffc0203268:	04c60613          	addi	a2,a2,76 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020326c:	22400593          	li	a1,548
ffffffffc0203270:	00003517          	auipc	a0,0x3
ffffffffc0203274:	4e050513          	addi	a0,a0,1248 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203278:	9d2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(*ptep & PTE_W);
ffffffffc020327c:	00003697          	auipc	a3,0x3
ffffffffc0203280:	7fc68693          	addi	a3,a3,2044 # ffffffffc0206a78 <etext+0x11d4>
ffffffffc0203284:	00003617          	auipc	a2,0x3
ffffffffc0203288:	02c60613          	addi	a2,a2,44 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020328c:	22300593          	li	a1,547
ffffffffc0203290:	00003517          	auipc	a0,0x3
ffffffffc0203294:	4c050513          	addi	a0,a0,1216 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203298:	9b2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(*ptep & PTE_U);
ffffffffc020329c:	00003697          	auipc	a3,0x3
ffffffffc02032a0:	7cc68693          	addi	a3,a3,1996 # ffffffffc0206a68 <etext+0x11c4>
ffffffffc02032a4:	00003617          	auipc	a2,0x3
ffffffffc02032a8:	00c60613          	addi	a2,a2,12 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02032ac:	22200593          	li	a1,546
ffffffffc02032b0:	00003517          	auipc	a0,0x3
ffffffffc02032b4:	4a050513          	addi	a0,a0,1184 # ffffffffc0206750 <etext+0xeac>
ffffffffc02032b8:	992fd0ef          	jal	ffffffffc020044a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02032bc:	00003617          	auipc	a2,0x3
ffffffffc02032c0:	44c60613          	addi	a2,a2,1100 # ffffffffc0206708 <etext+0xe64>
ffffffffc02032c4:	08100593          	li	a1,129
ffffffffc02032c8:	00003517          	auipc	a0,0x3
ffffffffc02032cc:	48850513          	addi	a0,a0,1160 # ffffffffc0206750 <etext+0xeac>
ffffffffc02032d0:	97afd0ef          	jal	ffffffffc020044a <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02032d4:	00003697          	auipc	a3,0x3
ffffffffc02032d8:	6ec68693          	addi	a3,a3,1772 # ffffffffc02069c0 <etext+0x111c>
ffffffffc02032dc:	00003617          	auipc	a2,0x3
ffffffffc02032e0:	fd460613          	addi	a2,a2,-44 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02032e4:	21d00593          	li	a1,541
ffffffffc02032e8:	00003517          	auipc	a0,0x3
ffffffffc02032ec:	46850513          	addi	a0,a0,1128 # ffffffffc0206750 <etext+0xeac>
ffffffffc02032f0:	95afd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02032f4:	00003697          	auipc	a3,0x3
ffffffffc02032f8:	73c68693          	addi	a3,a3,1852 # ffffffffc0206a30 <etext+0x118c>
ffffffffc02032fc:	00003617          	auipc	a2,0x3
ffffffffc0203300:	fb460613          	addi	a2,a2,-76 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203304:	22100593          	li	a1,545
ffffffffc0203308:	00003517          	auipc	a0,0x3
ffffffffc020330c:	44850513          	addi	a0,a0,1096 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203310:	93afd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203314:	00003697          	auipc	a3,0x3
ffffffffc0203318:	6dc68693          	addi	a3,a3,1756 # ffffffffc02069f0 <etext+0x114c>
ffffffffc020331c:	00003617          	auipc	a2,0x3
ffffffffc0203320:	f9460613          	addi	a2,a2,-108 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203324:	22000593          	li	a1,544
ffffffffc0203328:	00003517          	auipc	a0,0x3
ffffffffc020332c:	42850513          	addi	a0,a0,1064 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203330:	91afd0ef          	jal	ffffffffc020044a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203334:	86d6                	mv	a3,s5
ffffffffc0203336:	00003617          	auipc	a2,0x3
ffffffffc020333a:	32a60613          	addi	a2,a2,810 # ffffffffc0206660 <etext+0xdbc>
ffffffffc020333e:	21c00593          	li	a1,540
ffffffffc0203342:	00003517          	auipc	a0,0x3
ffffffffc0203346:	40e50513          	addi	a0,a0,1038 # ffffffffc0206750 <etext+0xeac>
ffffffffc020334a:	900fd0ef          	jal	ffffffffc020044a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020334e:	00003617          	auipc	a2,0x3
ffffffffc0203352:	31260613          	addi	a2,a2,786 # ffffffffc0206660 <etext+0xdbc>
ffffffffc0203356:	21b00593          	li	a1,539
ffffffffc020335a:	00003517          	auipc	a0,0x3
ffffffffc020335e:	3f650513          	addi	a0,a0,1014 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203362:	8e8fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203366:	00003697          	auipc	a3,0x3
ffffffffc020336a:	64268693          	addi	a3,a3,1602 # ffffffffc02069a8 <etext+0x1104>
ffffffffc020336e:	00003617          	auipc	a2,0x3
ffffffffc0203372:	f4260613          	addi	a2,a2,-190 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203376:	21900593          	li	a1,537
ffffffffc020337a:	00003517          	auipc	a0,0x3
ffffffffc020337e:	3d650513          	addi	a0,a0,982 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203382:	8c8fd0ef          	jal	ffffffffc020044a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203386:	00003697          	auipc	a3,0x3
ffffffffc020338a:	60a68693          	addi	a3,a3,1546 # ffffffffc0206990 <etext+0x10ec>
ffffffffc020338e:	00003617          	auipc	a2,0x3
ffffffffc0203392:	f2260613          	addi	a2,a2,-222 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203396:	21800593          	li	a1,536
ffffffffc020339a:	00003517          	auipc	a0,0x3
ffffffffc020339e:	3b650513          	addi	a0,a0,950 # ffffffffc0206750 <etext+0xeac>
ffffffffc02033a2:	8a8fd0ef          	jal	ffffffffc020044a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02033a6:	00004697          	auipc	a3,0x4
ffffffffc02033aa:	99a68693          	addi	a3,a3,-1638 # ffffffffc0206d40 <etext+0x149c>
ffffffffc02033ae:	00003617          	auipc	a2,0x3
ffffffffc02033b2:	f0260613          	addi	a2,a2,-254 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02033b6:	25f00593          	li	a1,607
ffffffffc02033ba:	00003517          	auipc	a0,0x3
ffffffffc02033be:	39650513          	addi	a0,a0,918 # ffffffffc0206750 <etext+0xeac>
ffffffffc02033c2:	888fd0ef          	jal	ffffffffc020044a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02033c6:	00004697          	auipc	a3,0x4
ffffffffc02033ca:	94268693          	addi	a3,a3,-1726 # ffffffffc0206d08 <etext+0x1464>
ffffffffc02033ce:	00003617          	auipc	a2,0x3
ffffffffc02033d2:	ee260613          	addi	a2,a2,-286 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02033d6:	25c00593          	li	a1,604
ffffffffc02033da:	00003517          	auipc	a0,0x3
ffffffffc02033de:	37650513          	addi	a0,a0,886 # ffffffffc0206750 <etext+0xeac>
ffffffffc02033e2:	868fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p) == 2);
ffffffffc02033e6:	00004697          	auipc	a3,0x4
ffffffffc02033ea:	8f268693          	addi	a3,a3,-1806 # ffffffffc0206cd8 <etext+0x1434>
ffffffffc02033ee:	00003617          	auipc	a2,0x3
ffffffffc02033f2:	ec260613          	addi	a2,a2,-318 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02033f6:	25800593          	li	a1,600
ffffffffc02033fa:	00003517          	auipc	a0,0x3
ffffffffc02033fe:	35650513          	addi	a0,a0,854 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203402:	848fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203406:	00004697          	auipc	a3,0x4
ffffffffc020340a:	88a68693          	addi	a3,a3,-1910 # ffffffffc0206c90 <etext+0x13ec>
ffffffffc020340e:	00003617          	auipc	a2,0x3
ffffffffc0203412:	ea260613          	addi	a2,a2,-350 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203416:	25700593          	li	a1,599
ffffffffc020341a:	00003517          	auipc	a0,0x3
ffffffffc020341e:	33650513          	addi	a0,a0,822 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203422:	828fd0ef          	jal	ffffffffc020044a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0203426:	00003697          	auipc	a3,0x3
ffffffffc020342a:	4da68693          	addi	a3,a3,1242 # ffffffffc0206900 <etext+0x105c>
ffffffffc020342e:	00003617          	auipc	a2,0x3
ffffffffc0203432:	e8260613          	addi	a2,a2,-382 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203436:	21000593          	li	a1,528
ffffffffc020343a:	00003517          	auipc	a0,0x3
ffffffffc020343e:	31650513          	addi	a0,a0,790 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203442:	808fd0ef          	jal	ffffffffc020044a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203446:	00003617          	auipc	a2,0x3
ffffffffc020344a:	2c260613          	addi	a2,a2,706 # ffffffffc0206708 <etext+0xe64>
ffffffffc020344e:	0c900593          	li	a1,201
ffffffffc0203452:	00003517          	auipc	a0,0x3
ffffffffc0203456:	2fe50513          	addi	a0,a0,766 # ffffffffc0206750 <etext+0xeac>
ffffffffc020345a:	ff1fc0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020345e:	00003697          	auipc	a3,0x3
ffffffffc0203462:	50268693          	addi	a3,a3,1282 # ffffffffc0206960 <etext+0x10bc>
ffffffffc0203466:	00003617          	auipc	a2,0x3
ffffffffc020346a:	e4a60613          	addi	a2,a2,-438 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020346e:	21700593          	li	a1,535
ffffffffc0203472:	00003517          	auipc	a0,0x3
ffffffffc0203476:	2de50513          	addi	a0,a0,734 # ffffffffc0206750 <etext+0xeac>
ffffffffc020347a:	fd1fc0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020347e:	00003697          	auipc	a3,0x3
ffffffffc0203482:	4b268693          	addi	a3,a3,1202 # ffffffffc0206930 <etext+0x108c>
ffffffffc0203486:	00003617          	auipc	a2,0x3
ffffffffc020348a:	e2a60613          	addi	a2,a2,-470 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020348e:	21400593          	li	a1,532
ffffffffc0203492:	00003517          	auipc	a0,0x3
ffffffffc0203496:	2be50513          	addi	a0,a0,702 # ffffffffc0206750 <etext+0xeac>
ffffffffc020349a:	fb1fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc020349e <pgdir_alloc_page>:
{
ffffffffc020349e:	7139                	addi	sp,sp,-64
ffffffffc02034a0:	f426                	sd	s1,40(sp)
ffffffffc02034a2:	f04a                	sd	s2,32(sp)
ffffffffc02034a4:	ec4e                	sd	s3,24(sp)
ffffffffc02034a6:	fc06                	sd	ra,56(sp)
ffffffffc02034a8:	f822                	sd	s0,48(sp)
ffffffffc02034aa:	892a                	mv	s2,a0
ffffffffc02034ac:	84ae                	mv	s1,a1
ffffffffc02034ae:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034b0:	100027f3          	csrr	a5,sstatus
ffffffffc02034b4:	8b89                	andi	a5,a5,2
ffffffffc02034b6:	ebb5                	bnez	a5,ffffffffc020352a <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034b8:	000b2417          	auipc	s0,0xb2
ffffffffc02034bc:	1b040413          	addi	s0,s0,432 # ffffffffc02b5668 <pmm_manager>
ffffffffc02034c0:	601c                	ld	a5,0(s0)
ffffffffc02034c2:	4505                	li	a0,1
ffffffffc02034c4:	6f9c                	ld	a5,24(a5)
ffffffffc02034c6:	9782                	jalr	a5
ffffffffc02034c8:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc02034ca:	c5b9                	beqz	a1,ffffffffc0203518 <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02034cc:	86ce                	mv	a3,s3
ffffffffc02034ce:	854a                	mv	a0,s2
ffffffffc02034d0:	8626                	mv	a2,s1
ffffffffc02034d2:	e42e                	sd	a1,8(sp)
ffffffffc02034d4:	a8aff0ef          	jal	ffffffffc020275e <page_insert>
ffffffffc02034d8:	65a2                	ld	a1,8(sp)
ffffffffc02034da:	e515                	bnez	a0,ffffffffc0203506 <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc02034dc:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc02034de:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc02034e0:	4785                	li	a5,1
ffffffffc02034e2:	02f70c63          	beq	a4,a5,ffffffffc020351a <pgdir_alloc_page+0x7c>
ffffffffc02034e6:	00004697          	auipc	a3,0x4
ffffffffc02034ea:	8a268693          	addi	a3,a3,-1886 # ffffffffc0206d88 <etext+0x14e4>
ffffffffc02034ee:	00003617          	auipc	a2,0x3
ffffffffc02034f2:	dc260613          	addi	a2,a2,-574 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02034f6:	1f500593          	li	a1,501
ffffffffc02034fa:	00003517          	auipc	a0,0x3
ffffffffc02034fe:	25650513          	addi	a0,a0,598 # ffffffffc0206750 <etext+0xeac>
ffffffffc0203502:	f49fc0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0203506:	100027f3          	csrr	a5,sstatus
ffffffffc020350a:	8b89                	andi	a5,a5,2
ffffffffc020350c:	ef95                	bnez	a5,ffffffffc0203548 <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc020350e:	601c                	ld	a5,0(s0)
ffffffffc0203510:	852e                	mv	a0,a1
ffffffffc0203512:	4585                	li	a1,1
ffffffffc0203514:	739c                	ld	a5,32(a5)
ffffffffc0203516:	9782                	jalr	a5
            return NULL;
ffffffffc0203518:	4581                	li	a1,0
}
ffffffffc020351a:	70e2                	ld	ra,56(sp)
ffffffffc020351c:	7442                	ld	s0,48(sp)
ffffffffc020351e:	74a2                	ld	s1,40(sp)
ffffffffc0203520:	7902                	ld	s2,32(sp)
ffffffffc0203522:	69e2                	ld	s3,24(sp)
ffffffffc0203524:	852e                	mv	a0,a1
ffffffffc0203526:	6121                	addi	sp,sp,64
ffffffffc0203528:	8082                	ret
        intr_disable();
ffffffffc020352a:	bd4fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020352e:	000b2417          	auipc	s0,0xb2
ffffffffc0203532:	13a40413          	addi	s0,s0,314 # ffffffffc02b5668 <pmm_manager>
ffffffffc0203536:	601c                	ld	a5,0(s0)
ffffffffc0203538:	4505                	li	a0,1
ffffffffc020353a:	6f9c                	ld	a5,24(a5)
ffffffffc020353c:	9782                	jalr	a5
ffffffffc020353e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0203540:	bb8fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0203544:	65a2                	ld	a1,8(sp)
ffffffffc0203546:	b751                	j	ffffffffc02034ca <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc0203548:	bb6fd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020354c:	601c                	ld	a5,0(s0)
ffffffffc020354e:	6522                	ld	a0,8(sp)
ffffffffc0203550:	4585                	li	a1,1
ffffffffc0203552:	739c                	ld	a5,32(a5)
ffffffffc0203554:	9782                	jalr	a5
        intr_enable();
ffffffffc0203556:	ba2fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020355a:	bf7d                	j	ffffffffc0203518 <pgdir_alloc_page+0x7a>

ffffffffc020355c <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020355c:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020355e:	00004697          	auipc	a3,0x4
ffffffffc0203562:	84268693          	addi	a3,a3,-1982 # ffffffffc0206da0 <etext+0x14fc>
ffffffffc0203566:	00003617          	auipc	a2,0x3
ffffffffc020356a:	d4a60613          	addi	a2,a2,-694 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020356e:	07400593          	li	a1,116
ffffffffc0203572:	00004517          	auipc	a0,0x4
ffffffffc0203576:	84e50513          	addi	a0,a0,-1970 # ffffffffc0206dc0 <etext+0x151c>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020357a:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020357c:	ecffc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203580 <mm_create>:
{
ffffffffc0203580:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203582:	04000513          	li	a0,64
{
ffffffffc0203586:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203588:	e70fe0ef          	jal	ffffffffc0201bf8 <kmalloc>
    if (mm != NULL)
ffffffffc020358c:	cd19                	beqz	a0,ffffffffc02035aa <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc020358e:	e508                	sd	a0,8(a0)
ffffffffc0203590:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203592:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203596:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020359a:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020359e:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02035a2:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02035a6:	02053c23          	sd	zero,56(a0)
}
ffffffffc02035aa:	60a2                	ld	ra,8(sp)
ffffffffc02035ac:	0141                	addi	sp,sp,16
ffffffffc02035ae:	8082                	ret

ffffffffc02035b0 <find_vma>:
    if (mm != NULL)
ffffffffc02035b0:	c505                	beqz	a0,ffffffffc02035d8 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc02035b2:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02035b4:	c781                	beqz	a5,ffffffffc02035bc <find_vma+0xc>
ffffffffc02035b6:	6798                	ld	a4,8(a5)
ffffffffc02035b8:	02e5f363          	bgeu	a1,a4,ffffffffc02035de <find_vma+0x2e>
    return listelm->next;
ffffffffc02035bc:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc02035be:	00f50d63          	beq	a0,a5,ffffffffc02035d8 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02035c2:	fe87b703          	ld	a4,-24(a5) # fffffffffdffffe8 <end+0x3dd4a920>
ffffffffc02035c6:	00e5e663          	bltu	a1,a4,ffffffffc02035d2 <find_vma+0x22>
ffffffffc02035ca:	ff07b703          	ld	a4,-16(a5)
ffffffffc02035ce:	00e5ee63          	bltu	a1,a4,ffffffffc02035ea <find_vma+0x3a>
ffffffffc02035d2:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02035d4:	fef517e3          	bne	a0,a5,ffffffffc02035c2 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc02035d8:	4781                	li	a5,0
}
ffffffffc02035da:	853e                	mv	a0,a5
ffffffffc02035dc:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02035de:	6b98                	ld	a4,16(a5)
ffffffffc02035e0:	fce5fee3          	bgeu	a1,a4,ffffffffc02035bc <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc02035e4:	e91c                	sd	a5,16(a0)
}
ffffffffc02035e6:	853e                	mv	a0,a5
ffffffffc02035e8:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02035ea:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc02035ec:	e91c                	sd	a5,16(a0)
ffffffffc02035ee:	bfe5                	j	ffffffffc02035e6 <find_vma+0x36>

ffffffffc02035f0 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02035f0:	6590                	ld	a2,8(a1)
ffffffffc02035f2:	0105b803          	ld	a6,16(a1)
{
ffffffffc02035f6:	1141                	addi	sp,sp,-16
ffffffffc02035f8:	e406                	sd	ra,8(sp)
ffffffffc02035fa:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02035fc:	01066763          	bltu	a2,a6,ffffffffc020360a <insert_vma_struct+0x1a>
ffffffffc0203600:	a8b9                	j	ffffffffc020365e <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203602:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203606:	04e66763          	bltu	a2,a4,ffffffffc0203654 <insert_vma_struct+0x64>
ffffffffc020360a:	86be                	mv	a3,a5
ffffffffc020360c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020360e:	fef51ae3          	bne	a0,a5,ffffffffc0203602 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203612:	02a68463          	beq	a3,a0,ffffffffc020363a <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203616:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020361a:	fe86b883          	ld	a7,-24(a3)
ffffffffc020361e:	08e8f063          	bgeu	a7,a4,ffffffffc020369e <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203622:	04e66e63          	bltu	a2,a4,ffffffffc020367e <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0203626:	00f50a63          	beq	a0,a5,ffffffffc020363a <insert_vma_struct+0x4a>
ffffffffc020362a:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020362e:	05076863          	bltu	a4,a6,ffffffffc020367e <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0203632:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203636:	02c77263          	bgeu	a4,a2,ffffffffc020365a <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020363a:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020363c:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020363e:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203642:	e390                	sd	a2,0(a5)
ffffffffc0203644:	e690                	sd	a2,8(a3)
}
ffffffffc0203646:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203648:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020364a:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc020364c:	2705                	addiw	a4,a4,1
ffffffffc020364e:	d118                	sw	a4,32(a0)
}
ffffffffc0203650:	0141                	addi	sp,sp,16
ffffffffc0203652:	8082                	ret
    if (le_prev != list)
ffffffffc0203654:	fca691e3          	bne	a3,a0,ffffffffc0203616 <insert_vma_struct+0x26>
ffffffffc0203658:	bfd9                	j	ffffffffc020362e <insert_vma_struct+0x3e>
ffffffffc020365a:	f03ff0ef          	jal	ffffffffc020355c <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020365e:	00003697          	auipc	a3,0x3
ffffffffc0203662:	77268693          	addi	a3,a3,1906 # ffffffffc0206dd0 <etext+0x152c>
ffffffffc0203666:	00003617          	auipc	a2,0x3
ffffffffc020366a:	c4a60613          	addi	a2,a2,-950 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020366e:	07a00593          	li	a1,122
ffffffffc0203672:	00003517          	auipc	a0,0x3
ffffffffc0203676:	74e50513          	addi	a0,a0,1870 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc020367a:	dd1fc0ef          	jal	ffffffffc020044a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020367e:	00003697          	auipc	a3,0x3
ffffffffc0203682:	79268693          	addi	a3,a3,1938 # ffffffffc0206e10 <etext+0x156c>
ffffffffc0203686:	00003617          	auipc	a2,0x3
ffffffffc020368a:	c2a60613          	addi	a2,a2,-982 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020368e:	07300593          	li	a1,115
ffffffffc0203692:	00003517          	auipc	a0,0x3
ffffffffc0203696:	72e50513          	addi	a0,a0,1838 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc020369a:	db1fc0ef          	jal	ffffffffc020044a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020369e:	00003697          	auipc	a3,0x3
ffffffffc02036a2:	75268693          	addi	a3,a3,1874 # ffffffffc0206df0 <etext+0x154c>
ffffffffc02036a6:	00003617          	auipc	a2,0x3
ffffffffc02036aa:	c0a60613          	addi	a2,a2,-1014 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02036ae:	07200593          	li	a1,114
ffffffffc02036b2:	00003517          	auipc	a0,0x3
ffffffffc02036b6:	70e50513          	addi	a0,a0,1806 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc02036ba:	d91fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02036be <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02036be:	591c                	lw	a5,48(a0)
{
ffffffffc02036c0:	1141                	addi	sp,sp,-16
ffffffffc02036c2:	e406                	sd	ra,8(sp)
ffffffffc02036c4:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02036c6:	e78d                	bnez	a5,ffffffffc02036f0 <mm_destroy+0x32>
ffffffffc02036c8:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02036ca:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02036cc:	00a40c63          	beq	s0,a0,ffffffffc02036e4 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02036d0:	6118                	ld	a4,0(a0)
ffffffffc02036d2:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02036d4:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02036d6:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02036d8:	e398                	sd	a4,0(a5)
ffffffffc02036da:	dc4fe0ef          	jal	ffffffffc0201c9e <kfree>
    return listelm->next;
ffffffffc02036de:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02036e0:	fea418e3          	bne	s0,a0,ffffffffc02036d0 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02036e4:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02036e6:	6402                	ld	s0,0(sp)
ffffffffc02036e8:	60a2                	ld	ra,8(sp)
ffffffffc02036ea:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02036ec:	db2fe06f          	j	ffffffffc0201c9e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02036f0:	00003697          	auipc	a3,0x3
ffffffffc02036f4:	74068693          	addi	a3,a3,1856 # ffffffffc0206e30 <etext+0x158c>
ffffffffc02036f8:	00003617          	auipc	a2,0x3
ffffffffc02036fc:	bb860613          	addi	a2,a2,-1096 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203700:	09e00593          	li	a1,158
ffffffffc0203704:	00003517          	auipc	a0,0x3
ffffffffc0203708:	6bc50513          	addi	a0,a0,1724 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc020370c:	d3ffc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203710 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203710:	6785                	lui	a5,0x1
ffffffffc0203712:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7f29>
ffffffffc0203714:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc0203716:	4785                	li	a5,1
{
ffffffffc0203718:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020371a:	962e                	add	a2,a2,a1
ffffffffc020371c:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc020371e:	07fe                	slli	a5,a5,0x1f
{
ffffffffc0203720:	f822                	sd	s0,48(sp)
ffffffffc0203722:	f426                	sd	s1,40(sp)
ffffffffc0203724:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203728:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc020372c:	0785                	addi	a5,a5,1
ffffffffc020372e:	0084b633          	sltu	a2,s1,s0
ffffffffc0203732:	00f437b3          	sltu	a5,s0,a5
ffffffffc0203736:	00163613          	seqz	a2,a2
ffffffffc020373a:	0017b793          	seqz	a5,a5
{
ffffffffc020373e:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203740:	8fd1                	or	a5,a5,a2
ffffffffc0203742:	ebbd                	bnez	a5,ffffffffc02037b8 <mm_map+0xa8>
ffffffffc0203744:	002007b7          	lui	a5,0x200
ffffffffc0203748:	06f4e863          	bltu	s1,a5,ffffffffc02037b8 <mm_map+0xa8>
ffffffffc020374c:	f04a                	sd	s2,32(sp)
ffffffffc020374e:	ec4e                	sd	s3,24(sp)
ffffffffc0203750:	e852                	sd	s4,16(sp)
ffffffffc0203752:	892a                	mv	s2,a0
ffffffffc0203754:	89ba                	mv	s3,a4
ffffffffc0203756:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203758:	c135                	beqz	a0,ffffffffc02037bc <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc020375a:	85a6                	mv	a1,s1
ffffffffc020375c:	e55ff0ef          	jal	ffffffffc02035b0 <find_vma>
ffffffffc0203760:	c501                	beqz	a0,ffffffffc0203768 <mm_map+0x58>
ffffffffc0203762:	651c                	ld	a5,8(a0)
ffffffffc0203764:	0487e763          	bltu	a5,s0,ffffffffc02037b2 <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203768:	03000513          	li	a0,48
ffffffffc020376c:	c8cfe0ef          	jal	ffffffffc0201bf8 <kmalloc>
ffffffffc0203770:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203772:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203774:	c59d                	beqz	a1,ffffffffc02037a2 <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc0203776:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc0203778:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc020377a:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc020377e:	854a                	mv	a0,s2
ffffffffc0203780:	e42e                	sd	a1,8(sp)
ffffffffc0203782:	e6fff0ef          	jal	ffffffffc02035f0 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc0203786:	65a2                	ld	a1,8(sp)
ffffffffc0203788:	00098463          	beqz	s3,ffffffffc0203790 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc020378c:	00b9b023          	sd	a1,0(s3)
ffffffffc0203790:	7902                	ld	s2,32(sp)
ffffffffc0203792:	69e2                	ld	s3,24(sp)
ffffffffc0203794:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc0203796:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc0203798:	70e2                	ld	ra,56(sp)
ffffffffc020379a:	7442                	ld	s0,48(sp)
ffffffffc020379c:	74a2                	ld	s1,40(sp)
ffffffffc020379e:	6121                	addi	sp,sp,64
ffffffffc02037a0:	8082                	ret
ffffffffc02037a2:	70e2                	ld	ra,56(sp)
ffffffffc02037a4:	7442                	ld	s0,48(sp)
ffffffffc02037a6:	7902                	ld	s2,32(sp)
ffffffffc02037a8:	69e2                	ld	s3,24(sp)
ffffffffc02037aa:	6a42                	ld	s4,16(sp)
ffffffffc02037ac:	74a2                	ld	s1,40(sp)
ffffffffc02037ae:	6121                	addi	sp,sp,64
ffffffffc02037b0:	8082                	ret
ffffffffc02037b2:	7902                	ld	s2,32(sp)
ffffffffc02037b4:	69e2                	ld	s3,24(sp)
ffffffffc02037b6:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc02037b8:	5575                	li	a0,-3
ffffffffc02037ba:	bff9                	j	ffffffffc0203798 <mm_map+0x88>
    assert(mm != NULL);
ffffffffc02037bc:	00003697          	auipc	a3,0x3
ffffffffc02037c0:	68c68693          	addi	a3,a3,1676 # ffffffffc0206e48 <etext+0x15a4>
ffffffffc02037c4:	00003617          	auipc	a2,0x3
ffffffffc02037c8:	aec60613          	addi	a2,a2,-1300 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02037cc:	0b300593          	li	a1,179
ffffffffc02037d0:	00003517          	auipc	a0,0x3
ffffffffc02037d4:	5f050513          	addi	a0,a0,1520 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc02037d8:	c73fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02037dc <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02037dc:	7139                	addi	sp,sp,-64
ffffffffc02037de:	fc06                	sd	ra,56(sp)
ffffffffc02037e0:	f822                	sd	s0,48(sp)
ffffffffc02037e2:	f426                	sd	s1,40(sp)
ffffffffc02037e4:	f04a                	sd	s2,32(sp)
ffffffffc02037e6:	ec4e                	sd	s3,24(sp)
ffffffffc02037e8:	e852                	sd	s4,16(sp)
ffffffffc02037ea:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02037ec:	c525                	beqz	a0,ffffffffc0203854 <dup_mmap+0x78>
ffffffffc02037ee:	892a                	mv	s2,a0
ffffffffc02037f0:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02037f2:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02037f4:	c1a5                	beqz	a1,ffffffffc0203854 <dup_mmap+0x78>
    return listelm->prev;
ffffffffc02037f6:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02037f8:	04848c63          	beq	s1,s0,ffffffffc0203850 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02037fc:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203800:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203804:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203808:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020380c:	becfe0ef          	jal	ffffffffc0201bf8 <kmalloc>
    if (vma != NULL)
ffffffffc0203810:	c515                	beqz	a0,ffffffffc020383c <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203812:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203814:	01553423          	sd	s5,8(a0)
ffffffffc0203818:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020381c:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc0203820:	854a                	mv	a0,s2
ffffffffc0203822:	dcfff0ef          	jal	ffffffffc02035f0 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203826:	ff043683          	ld	a3,-16(s0)
ffffffffc020382a:	fe843603          	ld	a2,-24(s0)
ffffffffc020382e:	6c8c                	ld	a1,24(s1)
ffffffffc0203830:	01893503          	ld	a0,24(s2)
ffffffffc0203834:	4701                	li	a4,0
ffffffffc0203836:	cc7fe0ef          	jal	ffffffffc02024fc <copy_range>
ffffffffc020383a:	dd55                	beqz	a0,ffffffffc02037f6 <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc020383c:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020383e:	70e2                	ld	ra,56(sp)
ffffffffc0203840:	7442                	ld	s0,48(sp)
ffffffffc0203842:	74a2                	ld	s1,40(sp)
ffffffffc0203844:	7902                	ld	s2,32(sp)
ffffffffc0203846:	69e2                	ld	s3,24(sp)
ffffffffc0203848:	6a42                	ld	s4,16(sp)
ffffffffc020384a:	6aa2                	ld	s5,8(sp)
ffffffffc020384c:	6121                	addi	sp,sp,64
ffffffffc020384e:	8082                	ret
    return 0;
ffffffffc0203850:	4501                	li	a0,0
ffffffffc0203852:	b7f5                	j	ffffffffc020383e <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc0203854:	00003697          	auipc	a3,0x3
ffffffffc0203858:	60468693          	addi	a3,a3,1540 # ffffffffc0206e58 <etext+0x15b4>
ffffffffc020385c:	00003617          	auipc	a2,0x3
ffffffffc0203860:	a5460613          	addi	a2,a2,-1452 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203864:	0cf00593          	li	a1,207
ffffffffc0203868:	00003517          	auipc	a0,0x3
ffffffffc020386c:	55850513          	addi	a0,a0,1368 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203870:	bdbfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203874 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203874:	1101                	addi	sp,sp,-32
ffffffffc0203876:	ec06                	sd	ra,24(sp)
ffffffffc0203878:	e822                	sd	s0,16(sp)
ffffffffc020387a:	e426                	sd	s1,8(sp)
ffffffffc020387c:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020387e:	c531                	beqz	a0,ffffffffc02038ca <exit_mmap+0x56>
ffffffffc0203880:	591c                	lw	a5,48(a0)
ffffffffc0203882:	84aa                	mv	s1,a0
ffffffffc0203884:	e3b9                	bnez	a5,ffffffffc02038ca <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203886:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203888:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc020388c:	02850663          	beq	a0,s0,ffffffffc02038b8 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203890:	ff043603          	ld	a2,-16(s0)
ffffffffc0203894:	fe843583          	ld	a1,-24(s0)
ffffffffc0203898:	854a                	mv	a0,s2
ffffffffc020389a:	87bfe0ef          	jal	ffffffffc0202114 <unmap_range>
ffffffffc020389e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038a0:	fe8498e3          	bne	s1,s0,ffffffffc0203890 <exit_mmap+0x1c>
ffffffffc02038a4:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02038a6:	00848c63          	beq	s1,s0,ffffffffc02038be <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038aa:	ff043603          	ld	a2,-16(s0)
ffffffffc02038ae:	fe843583          	ld	a1,-24(s0)
ffffffffc02038b2:	854a                	mv	a0,s2
ffffffffc02038b4:	995fe0ef          	jal	ffffffffc0202248 <exit_range>
ffffffffc02038b8:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038ba:	fe8498e3          	bne	s1,s0,ffffffffc02038aa <exit_mmap+0x36>
    }
}
ffffffffc02038be:	60e2                	ld	ra,24(sp)
ffffffffc02038c0:	6442                	ld	s0,16(sp)
ffffffffc02038c2:	64a2                	ld	s1,8(sp)
ffffffffc02038c4:	6902                	ld	s2,0(sp)
ffffffffc02038c6:	6105                	addi	sp,sp,32
ffffffffc02038c8:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02038ca:	00003697          	auipc	a3,0x3
ffffffffc02038ce:	5ae68693          	addi	a3,a3,1454 # ffffffffc0206e78 <etext+0x15d4>
ffffffffc02038d2:	00003617          	auipc	a2,0x3
ffffffffc02038d6:	9de60613          	addi	a2,a2,-1570 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02038da:	0e800593          	li	a1,232
ffffffffc02038de:	00003517          	auipc	a0,0x3
ffffffffc02038e2:	4e250513          	addi	a0,a0,1250 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc02038e6:	b65fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02038ea <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02038ea:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038ec:	04000513          	li	a0,64
{
ffffffffc02038f0:	f406                	sd	ra,40(sp)
ffffffffc02038f2:	f022                	sd	s0,32(sp)
ffffffffc02038f4:	ec26                	sd	s1,24(sp)
ffffffffc02038f6:	e84a                	sd	s2,16(sp)
ffffffffc02038f8:	e44e                	sd	s3,8(sp)
ffffffffc02038fa:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038fc:	afcfe0ef          	jal	ffffffffc0201bf8 <kmalloc>
    if (mm != NULL)
ffffffffc0203900:	16050c63          	beqz	a0,ffffffffc0203a78 <vmm_init+0x18e>
ffffffffc0203904:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203906:	e508                	sd	a0,8(a0)
ffffffffc0203908:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020390a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020390e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203912:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203916:	02053423          	sd	zero,40(a0)
ffffffffc020391a:	02052823          	sw	zero,48(a0)
ffffffffc020391e:	02053c23          	sd	zero,56(a0)
ffffffffc0203922:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203926:	03000513          	li	a0,48
ffffffffc020392a:	acefe0ef          	jal	ffffffffc0201bf8 <kmalloc>
    if (vma != NULL)
ffffffffc020392e:	12050563          	beqz	a0,ffffffffc0203a58 <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203932:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203936:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203938:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc020393c:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020393e:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203940:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203942:	8522                	mv	a0,s0
ffffffffc0203944:	cadff0ef          	jal	ffffffffc02035f0 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203948:	fcf9                	bnez	s1,ffffffffc0203926 <vmm_init+0x3c>
ffffffffc020394a:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc020394e:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203952:	03000513          	li	a0,48
ffffffffc0203956:	aa2fe0ef          	jal	ffffffffc0201bf8 <kmalloc>
    if (vma != NULL)
ffffffffc020395a:	12050f63          	beqz	a0,ffffffffc0203a98 <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc020395e:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203962:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203964:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203968:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020396a:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc020396c:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc020396e:	8522                	mv	a0,s0
ffffffffc0203970:	c81ff0ef          	jal	ffffffffc02035f0 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203974:	fd249fe3          	bne	s1,s2,ffffffffc0203952 <vmm_init+0x68>
    return listelm->next;
ffffffffc0203978:	641c                	ld	a5,8(s0)
ffffffffc020397a:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc020397c:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203980:	1ef40c63          	beq	s0,a5,ffffffffc0203b78 <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203984:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f4aa8>
ffffffffc0203988:	ffe70693          	addi	a3,a4,-2
ffffffffc020398c:	12d61663          	bne	a2,a3,ffffffffc0203ab8 <vmm_init+0x1ce>
ffffffffc0203990:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203994:	12e69263          	bne	a3,a4,ffffffffc0203ab8 <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203998:	0715                	addi	a4,a4,5
ffffffffc020399a:	679c                	ld	a5,8(a5)
ffffffffc020399c:	feb712e3          	bne	a4,a1,ffffffffc0203980 <vmm_init+0x96>
ffffffffc02039a0:	491d                	li	s2,7
ffffffffc02039a2:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02039a4:	85a6                	mv	a1,s1
ffffffffc02039a6:	8522                	mv	a0,s0
ffffffffc02039a8:	c09ff0ef          	jal	ffffffffc02035b0 <find_vma>
ffffffffc02039ac:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc02039ae:	20050563          	beqz	a0,ffffffffc0203bb8 <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc02039b2:	00148593          	addi	a1,s1,1
ffffffffc02039b6:	8522                	mv	a0,s0
ffffffffc02039b8:	bf9ff0ef          	jal	ffffffffc02035b0 <find_vma>
ffffffffc02039bc:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc02039be:	1c050d63          	beqz	a0,ffffffffc0203b98 <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc02039c2:	85ca                	mv	a1,s2
ffffffffc02039c4:	8522                	mv	a0,s0
ffffffffc02039c6:	bebff0ef          	jal	ffffffffc02035b0 <find_vma>
        assert(vma3 == NULL);
ffffffffc02039ca:	18051763          	bnez	a0,ffffffffc0203b58 <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc02039ce:	00348593          	addi	a1,s1,3
ffffffffc02039d2:	8522                	mv	a0,s0
ffffffffc02039d4:	bddff0ef          	jal	ffffffffc02035b0 <find_vma>
        assert(vma4 == NULL);
ffffffffc02039d8:	16051063          	bnez	a0,ffffffffc0203b38 <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc02039dc:	00448593          	addi	a1,s1,4
ffffffffc02039e0:	8522                	mv	a0,s0
ffffffffc02039e2:	bcfff0ef          	jal	ffffffffc02035b0 <find_vma>
        assert(vma5 == NULL);
ffffffffc02039e6:	12051963          	bnez	a0,ffffffffc0203b18 <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02039ea:	008a3783          	ld	a5,8(s4)
ffffffffc02039ee:	10979563          	bne	a5,s1,ffffffffc0203af8 <vmm_init+0x20e>
ffffffffc02039f2:	010a3783          	ld	a5,16(s4)
ffffffffc02039f6:	11279163          	bne	a5,s2,ffffffffc0203af8 <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02039fa:	0089b783          	ld	a5,8(s3)
ffffffffc02039fe:	0c979d63          	bne	a5,s1,ffffffffc0203ad8 <vmm_init+0x1ee>
ffffffffc0203a02:	0109b783          	ld	a5,16(s3)
ffffffffc0203a06:	0d279963          	bne	a5,s2,ffffffffc0203ad8 <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a0a:	0495                	addi	s1,s1,5
ffffffffc0203a0c:	1f900793          	li	a5,505
ffffffffc0203a10:	0915                	addi	s2,s2,5
ffffffffc0203a12:	f8f499e3          	bne	s1,a5,ffffffffc02039a4 <vmm_init+0xba>
ffffffffc0203a16:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203a18:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203a1a:	85a6                	mv	a1,s1
ffffffffc0203a1c:	8522                	mv	a0,s0
ffffffffc0203a1e:	b93ff0ef          	jal	ffffffffc02035b0 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203a22:	1a051b63          	bnez	a0,ffffffffc0203bd8 <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203a26:	14fd                	addi	s1,s1,-1
ffffffffc0203a28:	ff2499e3          	bne	s1,s2,ffffffffc0203a1a <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203a2c:	8522                	mv	a0,s0
ffffffffc0203a2e:	c91ff0ef          	jal	ffffffffc02036be <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203a32:	00003517          	auipc	a0,0x3
ffffffffc0203a36:	5b650513          	addi	a0,a0,1462 # ffffffffc0206fe8 <etext+0x1744>
ffffffffc0203a3a:	f5efc0ef          	jal	ffffffffc0200198 <cprintf>
}
ffffffffc0203a3e:	7402                	ld	s0,32(sp)
ffffffffc0203a40:	70a2                	ld	ra,40(sp)
ffffffffc0203a42:	64e2                	ld	s1,24(sp)
ffffffffc0203a44:	6942                	ld	s2,16(sp)
ffffffffc0203a46:	69a2                	ld	s3,8(sp)
ffffffffc0203a48:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a4a:	00003517          	auipc	a0,0x3
ffffffffc0203a4e:	5be50513          	addi	a0,a0,1470 # ffffffffc0207008 <etext+0x1764>
}
ffffffffc0203a52:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a54:	f44fc06f          	j	ffffffffc0200198 <cprintf>
        assert(vma != NULL);
ffffffffc0203a58:	00003697          	auipc	a3,0x3
ffffffffc0203a5c:	44068693          	addi	a3,a3,1088 # ffffffffc0206e98 <etext+0x15f4>
ffffffffc0203a60:	00003617          	auipc	a2,0x3
ffffffffc0203a64:	85060613          	addi	a2,a2,-1968 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203a68:	12c00593          	li	a1,300
ffffffffc0203a6c:	00003517          	auipc	a0,0x3
ffffffffc0203a70:	35450513          	addi	a0,a0,852 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203a74:	9d7fc0ef          	jal	ffffffffc020044a <__panic>
    assert(mm != NULL);
ffffffffc0203a78:	00003697          	auipc	a3,0x3
ffffffffc0203a7c:	3d068693          	addi	a3,a3,976 # ffffffffc0206e48 <etext+0x15a4>
ffffffffc0203a80:	00003617          	auipc	a2,0x3
ffffffffc0203a84:	83060613          	addi	a2,a2,-2000 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203a88:	12400593          	li	a1,292
ffffffffc0203a8c:	00003517          	auipc	a0,0x3
ffffffffc0203a90:	33450513          	addi	a0,a0,820 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203a94:	9b7fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma != NULL);
ffffffffc0203a98:	00003697          	auipc	a3,0x3
ffffffffc0203a9c:	40068693          	addi	a3,a3,1024 # ffffffffc0206e98 <etext+0x15f4>
ffffffffc0203aa0:	00003617          	auipc	a2,0x3
ffffffffc0203aa4:	81060613          	addi	a2,a2,-2032 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203aa8:	13300593          	li	a1,307
ffffffffc0203aac:	00003517          	auipc	a0,0x3
ffffffffc0203ab0:	31450513          	addi	a0,a0,788 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203ab4:	997fc0ef          	jal	ffffffffc020044a <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ab8:	00003697          	auipc	a3,0x3
ffffffffc0203abc:	40868693          	addi	a3,a3,1032 # ffffffffc0206ec0 <etext+0x161c>
ffffffffc0203ac0:	00002617          	auipc	a2,0x2
ffffffffc0203ac4:	7f060613          	addi	a2,a2,2032 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203ac8:	13d00593          	li	a1,317
ffffffffc0203acc:	00003517          	auipc	a0,0x3
ffffffffc0203ad0:	2f450513          	addi	a0,a0,756 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203ad4:	977fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203ad8:	00003697          	auipc	a3,0x3
ffffffffc0203adc:	4a068693          	addi	a3,a3,1184 # ffffffffc0206f78 <etext+0x16d4>
ffffffffc0203ae0:	00002617          	auipc	a2,0x2
ffffffffc0203ae4:	7d060613          	addi	a2,a2,2000 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203ae8:	14f00593          	li	a1,335
ffffffffc0203aec:	00003517          	auipc	a0,0x3
ffffffffc0203af0:	2d450513          	addi	a0,a0,724 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203af4:	957fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203af8:	00003697          	auipc	a3,0x3
ffffffffc0203afc:	45068693          	addi	a3,a3,1104 # ffffffffc0206f48 <etext+0x16a4>
ffffffffc0203b00:	00002617          	auipc	a2,0x2
ffffffffc0203b04:	7b060613          	addi	a2,a2,1968 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203b08:	14e00593          	li	a1,334
ffffffffc0203b0c:	00003517          	auipc	a0,0x3
ffffffffc0203b10:	2b450513          	addi	a0,a0,692 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203b14:	937fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma5 == NULL);
ffffffffc0203b18:	00003697          	auipc	a3,0x3
ffffffffc0203b1c:	42068693          	addi	a3,a3,1056 # ffffffffc0206f38 <etext+0x1694>
ffffffffc0203b20:	00002617          	auipc	a2,0x2
ffffffffc0203b24:	79060613          	addi	a2,a2,1936 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203b28:	14c00593          	li	a1,332
ffffffffc0203b2c:	00003517          	auipc	a0,0x3
ffffffffc0203b30:	29450513          	addi	a0,a0,660 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203b34:	917fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma4 == NULL);
ffffffffc0203b38:	00003697          	auipc	a3,0x3
ffffffffc0203b3c:	3f068693          	addi	a3,a3,1008 # ffffffffc0206f28 <etext+0x1684>
ffffffffc0203b40:	00002617          	auipc	a2,0x2
ffffffffc0203b44:	77060613          	addi	a2,a2,1904 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203b48:	14a00593          	li	a1,330
ffffffffc0203b4c:	00003517          	auipc	a0,0x3
ffffffffc0203b50:	27450513          	addi	a0,a0,628 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203b54:	8f7fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma3 == NULL);
ffffffffc0203b58:	00003697          	auipc	a3,0x3
ffffffffc0203b5c:	3c068693          	addi	a3,a3,960 # ffffffffc0206f18 <etext+0x1674>
ffffffffc0203b60:	00002617          	auipc	a2,0x2
ffffffffc0203b64:	75060613          	addi	a2,a2,1872 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203b68:	14800593          	li	a1,328
ffffffffc0203b6c:	00003517          	auipc	a0,0x3
ffffffffc0203b70:	25450513          	addi	a0,a0,596 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203b74:	8d7fc0ef          	jal	ffffffffc020044a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203b78:	00003697          	auipc	a3,0x3
ffffffffc0203b7c:	33068693          	addi	a3,a3,816 # ffffffffc0206ea8 <etext+0x1604>
ffffffffc0203b80:	00002617          	auipc	a2,0x2
ffffffffc0203b84:	73060613          	addi	a2,a2,1840 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203b88:	13b00593          	li	a1,315
ffffffffc0203b8c:	00003517          	auipc	a0,0x3
ffffffffc0203b90:	23450513          	addi	a0,a0,564 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203b94:	8b7fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma2 != NULL);
ffffffffc0203b98:	00003697          	auipc	a3,0x3
ffffffffc0203b9c:	37068693          	addi	a3,a3,880 # ffffffffc0206f08 <etext+0x1664>
ffffffffc0203ba0:	00002617          	auipc	a2,0x2
ffffffffc0203ba4:	71060613          	addi	a2,a2,1808 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203ba8:	14600593          	li	a1,326
ffffffffc0203bac:	00003517          	auipc	a0,0x3
ffffffffc0203bb0:	21450513          	addi	a0,a0,532 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203bb4:	897fc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma1 != NULL);
ffffffffc0203bb8:	00003697          	auipc	a3,0x3
ffffffffc0203bbc:	34068693          	addi	a3,a3,832 # ffffffffc0206ef8 <etext+0x1654>
ffffffffc0203bc0:	00002617          	auipc	a2,0x2
ffffffffc0203bc4:	6f060613          	addi	a2,a2,1776 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203bc8:	14400593          	li	a1,324
ffffffffc0203bcc:	00003517          	auipc	a0,0x3
ffffffffc0203bd0:	1f450513          	addi	a0,a0,500 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203bd4:	877fc0ef          	jal	ffffffffc020044a <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203bd8:	6914                	ld	a3,16(a0)
ffffffffc0203bda:	6510                	ld	a2,8(a0)
ffffffffc0203bdc:	0004859b          	sext.w	a1,s1
ffffffffc0203be0:	00003517          	auipc	a0,0x3
ffffffffc0203be4:	3c850513          	addi	a0,a0,968 # ffffffffc0206fa8 <etext+0x1704>
ffffffffc0203be8:	db0fc0ef          	jal	ffffffffc0200198 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203bec:	00003697          	auipc	a3,0x3
ffffffffc0203bf0:	3e468693          	addi	a3,a3,996 # ffffffffc0206fd0 <etext+0x172c>
ffffffffc0203bf4:	00002617          	auipc	a2,0x2
ffffffffc0203bf8:	6bc60613          	addi	a2,a2,1724 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0203bfc:	15900593          	li	a1,345
ffffffffc0203c00:	00003517          	auipc	a0,0x3
ffffffffc0203c04:	1c050513          	addi	a0,a0,448 # ffffffffc0206dc0 <etext+0x151c>
ffffffffc0203c08:	843fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203c0c <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203c0c:	7179                	addi	sp,sp,-48
ffffffffc0203c0e:	f022                	sd	s0,32(sp)
ffffffffc0203c10:	f406                	sd	ra,40(sp)
ffffffffc0203c12:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203c14:	c52d                	beqz	a0,ffffffffc0203c7e <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203c16:	002007b7          	lui	a5,0x200
ffffffffc0203c1a:	04f5ed63          	bltu	a1,a5,ffffffffc0203c74 <user_mem_check+0x68>
ffffffffc0203c1e:	ec26                	sd	s1,24(sp)
ffffffffc0203c20:	00c584b3          	add	s1,a1,a2
ffffffffc0203c24:	0695ff63          	bgeu	a1,s1,ffffffffc0203ca2 <user_mem_check+0x96>
ffffffffc0203c28:	4785                	li	a5,1
ffffffffc0203c2a:	07fe                	slli	a5,a5,0x1f
ffffffffc0203c2c:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_matrix_out_size+0x1f4ac1>
ffffffffc0203c2e:	06f4fa63          	bgeu	s1,a5,ffffffffc0203ca2 <user_mem_check+0x96>
ffffffffc0203c32:	e84a                	sd	s2,16(sp)
ffffffffc0203c34:	e44e                	sd	s3,8(sp)
ffffffffc0203c36:	8936                	mv	s2,a3
ffffffffc0203c38:	89aa                	mv	s3,a0
ffffffffc0203c3a:	a829                	j	ffffffffc0203c54 <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c3c:	6685                	lui	a3,0x1
ffffffffc0203c3e:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c40:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c44:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c46:	c685                	beqz	a3,ffffffffc0203c6e <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c48:	c399                	beqz	a5,ffffffffc0203c4e <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c4a:	02e46263          	bltu	s0,a4,ffffffffc0203c6e <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203c4e:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203c50:	04947b63          	bgeu	s0,s1,ffffffffc0203ca6 <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203c54:	85a2                	mv	a1,s0
ffffffffc0203c56:	854e                	mv	a0,s3
ffffffffc0203c58:	959ff0ef          	jal	ffffffffc02035b0 <find_vma>
ffffffffc0203c5c:	c909                	beqz	a0,ffffffffc0203c6e <user_mem_check+0x62>
ffffffffc0203c5e:	6518                	ld	a4,8(a0)
ffffffffc0203c60:	00e46763          	bltu	s0,a4,ffffffffc0203c6e <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c64:	4d1c                	lw	a5,24(a0)
ffffffffc0203c66:	fc091be3          	bnez	s2,ffffffffc0203c3c <user_mem_check+0x30>
ffffffffc0203c6a:	8b85                	andi	a5,a5,1
ffffffffc0203c6c:	f3ed                	bnez	a5,ffffffffc0203c4e <user_mem_check+0x42>
ffffffffc0203c6e:	64e2                	ld	s1,24(sp)
ffffffffc0203c70:	6942                	ld	s2,16(sp)
ffffffffc0203c72:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203c74:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203c76:	70a2                	ld	ra,40(sp)
ffffffffc0203c78:	7402                	ld	s0,32(sp)
ffffffffc0203c7a:	6145                	addi	sp,sp,48
ffffffffc0203c7c:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203c7e:	c02007b7          	lui	a5,0xc0200
ffffffffc0203c82:	fef5eae3          	bltu	a1,a5,ffffffffc0203c76 <user_mem_check+0x6a>
ffffffffc0203c86:	c80007b7          	lui	a5,0xc8000
ffffffffc0203c8a:	962e                	add	a2,a2,a1
ffffffffc0203c8c:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d4a939>
ffffffffc0203c8e:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203c92:	00f63633          	sltu	a2,a2,a5
}
ffffffffc0203c96:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203c98:	00867533          	and	a0,a2,s0
}
ffffffffc0203c9c:	7402                	ld	s0,32(sp)
ffffffffc0203c9e:	6145                	addi	sp,sp,48
ffffffffc0203ca0:	8082                	ret
ffffffffc0203ca2:	64e2                	ld	s1,24(sp)
ffffffffc0203ca4:	bfc1                	j	ffffffffc0203c74 <user_mem_check+0x68>
ffffffffc0203ca6:	64e2                	ld	s1,24(sp)
ffffffffc0203ca8:	6942                	ld	s2,16(sp)
ffffffffc0203caa:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203cac:	4505                	li	a0,1
ffffffffc0203cae:	b7e1                	j	ffffffffc0203c76 <user_mem_check+0x6a>

ffffffffc0203cb0 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203cb0:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203cb2:	9402                	jalr	s0

	jal do_exit
ffffffffc0203cb4:	5e8000ef          	jal	ffffffffc020429c <do_exit>

ffffffffc0203cb8 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203cb8:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203cba:	14800513          	li	a0,328
{
ffffffffc0203cbe:	e022                	sd	s0,0(sp)
ffffffffc0203cc0:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203cc2:	f37fd0ef          	jal	ffffffffc0201bf8 <kmalloc>
ffffffffc0203cc6:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203cc8:	c141                	beqz	a0,ffffffffc0203d48 <alloc_proc+0x90>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc0203cca:	57fd                	li	a5,-1
ffffffffc0203ccc:	1782                	slli	a5,a5,0x20
ffffffffc0203cce:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0203cd0:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203cd4:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203cd8:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203cdc:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203ce0:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203ce4:	07000613          	li	a2,112
ffffffffc0203ce8:	4581                	li	a1,0
ffffffffc0203cea:	03050513          	addi	a0,a0,48
ffffffffc0203cee:	38d010ef          	jal	ffffffffc020587a <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203cf2:	000b2797          	auipc	a5,0xb2
ffffffffc0203cf6:	97e7b783          	ld	a5,-1666(a5) # ffffffffc02b5670 <boot_pgdir_pa>
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203cfa:	4641                	li	a2,16
ffffffffc0203cfc:	4581                	li	a1,0
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203cfe:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203d00:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203d04:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203d08:	0b440513          	addi	a0,s0,180
ffffffffc0203d0c:	36f010ef          	jal	ffffffffc020587a <memset>
         *       skew_heap_entry_t lab6_run_pool;            // entry in the run pool (lab6 stride)
         *       uint32_t lab6_stride;                       // stride value (lab6 stride)
         *       uint32_t lab6_priority;                     // priority value (lab6 stride)
         */
        proc->rq = NULL;
        list_init(&proc->run_link);
ffffffffc0203d10:	11040793          	addi	a5,s0,272
    elm->prev = elm->next = elm;
ffffffffc0203d14:	10f43c23          	sd	a5,280(s0)
ffffffffc0203d18:	10f43823          	sd	a5,272(s0)
        proc->exit_code = 0;
ffffffffc0203d1c:	0e043423          	sd	zero,232(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203d20:	0e043823          	sd	zero,240(s0)
ffffffffc0203d24:	0e043c23          	sd	zero,248(s0)
ffffffffc0203d28:	10043023          	sd	zero,256(s0)
        proc->rq = NULL;
ffffffffc0203d2c:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;
ffffffffc0203d30:	12042023          	sw	zero,288(s0)
        memset(&proc->lab6_run_pool, 0, sizeof(proc->lab6_run_pool));
ffffffffc0203d34:	12840513          	addi	a0,s0,296
ffffffffc0203d38:	4661                	li	a2,24
ffffffffc0203d3a:	4581                	li	a1,0
ffffffffc0203d3c:	33f010ef          	jal	ffffffffc020587a <memset>
        proc->lab6_stride = 0;
ffffffffc0203d40:	4785                	li	a5,1
ffffffffc0203d42:	1782                	slli	a5,a5,0x20
ffffffffc0203d44:	14f43023          	sd	a5,320(s0)
        proc->lab6_priority = 1;
    }
    return proc;
}
ffffffffc0203d48:	60a2                	ld	ra,8(sp)
ffffffffc0203d4a:	8522                	mv	a0,s0
ffffffffc0203d4c:	6402                	ld	s0,0(sp)
ffffffffc0203d4e:	0141                	addi	sp,sp,16
ffffffffc0203d50:	8082                	ret

ffffffffc0203d52 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203d52:	000b2797          	auipc	a5,0xb2
ffffffffc0203d56:	94e7b783          	ld	a5,-1714(a5) # ffffffffc02b56a0 <current>
ffffffffc0203d5a:	73c8                	ld	a0,160(a5)
ffffffffc0203d5c:	92afd06f          	j	ffffffffc0200e86 <forkrets>

ffffffffc0203d60 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203d60:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203d62:	1141                	addi	sp,sp,-16
ffffffffc0203d64:	e406                	sd	ra,8(sp)
ffffffffc0203d66:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d6a:	02f6ee63          	bltu	a3,a5,ffffffffc0203da6 <put_pgdir+0x46>
ffffffffc0203d6e:	000b2717          	auipc	a4,0xb2
ffffffffc0203d72:	91273703          	ld	a4,-1774(a4) # ffffffffc02b5680 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203d76:	000b2797          	auipc	a5,0xb2
ffffffffc0203d7a:	9127b783          	ld	a5,-1774(a5) # ffffffffc02b5688 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203d7e:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203d80:	82b1                	srli	a3,a3,0xc
ffffffffc0203d82:	02f6fe63          	bgeu	a3,a5,ffffffffc0203dbe <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203d86:	00004797          	auipc	a5,0x4
ffffffffc0203d8a:	3ba7b783          	ld	a5,954(a5) # ffffffffc0208140 <nbase>
ffffffffc0203d8e:	000b2517          	auipc	a0,0xb2
ffffffffc0203d92:	90253503          	ld	a0,-1790(a0) # ffffffffc02b5690 <pages>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203d96:	60a2                	ld	ra,8(sp)
ffffffffc0203d98:	8e9d                	sub	a3,a3,a5
ffffffffc0203d9a:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203d9c:	4585                	li	a1,1
ffffffffc0203d9e:	9536                	add	a0,a0,a3
}
ffffffffc0203da0:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203da2:	852fe06f          	j	ffffffffc0201df4 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203da6:	00003617          	auipc	a2,0x3
ffffffffc0203daa:	96260613          	addi	a2,a2,-1694 # ffffffffc0206708 <etext+0xe64>
ffffffffc0203dae:	07700593          	li	a1,119
ffffffffc0203db2:	00003517          	auipc	a0,0x3
ffffffffc0203db6:	8d650513          	addi	a0,a0,-1834 # ffffffffc0206688 <etext+0xde4>
ffffffffc0203dba:	e90fc0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203dbe:	00003617          	auipc	a2,0x3
ffffffffc0203dc2:	97260613          	addi	a2,a2,-1678 # ffffffffc0206730 <etext+0xe8c>
ffffffffc0203dc6:	06900593          	li	a1,105
ffffffffc0203dca:	00003517          	auipc	a0,0x3
ffffffffc0203dce:	8be50513          	addi	a0,a0,-1858 # ffffffffc0206688 <etext+0xde4>
ffffffffc0203dd2:	e78fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203dd6 <proc_run>:
    if (proc != current)
ffffffffc0203dd6:	000b2697          	auipc	a3,0xb2
ffffffffc0203dda:	8ca68693          	addi	a3,a3,-1846 # ffffffffc02b56a0 <current>
ffffffffc0203dde:	6298                	ld	a4,0(a3)
ffffffffc0203de0:	06a70363          	beq	a4,a0,ffffffffc0203e46 <proc_run+0x70>
{
ffffffffc0203de4:	1101                	addi	sp,sp,-32
ffffffffc0203de6:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203de8:	100027f3          	csrr	a5,sstatus
ffffffffc0203dec:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203dee:	4801                	li	a6,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203df0:	eb9d                	bnez	a5,ffffffffc0203e26 <proc_run+0x50>
        proc->runs++; // 更新进程相关状态
ffffffffc0203df2:	4510                	lw	a2,8(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203df4:	755c                	ld	a5,168(a0)
        current=proc; // 切换进程
ffffffffc0203df6:	e288                	sd	a0,0(a3)
ffffffffc0203df8:	56fd                	li	a3,-1
        proc->runs++; // 更新进程相关状态
ffffffffc0203dfa:	2605                	addiw	a2,a2,1
ffffffffc0203dfc:	16fe                	slli	a3,a3,0x3f
ffffffffc0203dfe:	83b1                	srli	a5,a5,0xc
ffffffffc0203e00:	e442                	sd	a6,8(sp)
        current->need_resched = 0; // 不需要调度
ffffffffc0203e02:	00053c23          	sd	zero,24(a0)
        proc->runs++; // 更新进程相关状态
ffffffffc0203e06:	c510                	sw	a2,8(a0)
ffffffffc0203e08:	8fd5                	or	a5,a5,a3
ffffffffc0203e0a:	18079073          	csrw	satp,a5
        switch_to(&old->context,&proc->context); // 上下文切换
ffffffffc0203e0e:	03050593          	addi	a1,a0,48
ffffffffc0203e12:	03070513          	addi	a0,a4,48
ffffffffc0203e16:	1a6010ef          	jal	ffffffffc0204fbc <switch_to>
    if (flag)
ffffffffc0203e1a:	6822                	ld	a6,8(sp)
ffffffffc0203e1c:	02081163          	bnez	a6,ffffffffc0203e3e <proc_run+0x68>
}
ffffffffc0203e20:	60e2                	ld	ra,24(sp)
ffffffffc0203e22:	6105                	addi	sp,sp,32
ffffffffc0203e24:	8082                	ret
ffffffffc0203e26:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203e28:	ad7fc0ef          	jal	ffffffffc02008fe <intr_disable>
        if (proc == current) {
ffffffffc0203e2c:	000b2697          	auipc	a3,0xb2
ffffffffc0203e30:	87468693          	addi	a3,a3,-1932 # ffffffffc02b56a0 <current>
ffffffffc0203e34:	6298                	ld	a4,0(a3)
ffffffffc0203e36:	6522                	ld	a0,8(sp)
        return 1;
ffffffffc0203e38:	4805                	li	a6,1
ffffffffc0203e3a:	fae51ce3          	bne	a0,a4,ffffffffc0203df2 <proc_run+0x1c>
}
ffffffffc0203e3e:	60e2                	ld	ra,24(sp)
ffffffffc0203e40:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203e42:	ab7fc06f          	j	ffffffffc02008f8 <intr_enable>
ffffffffc0203e46:	8082                	ret

ffffffffc0203e48 <do_fork>:
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e48:	000b2797          	auipc	a5,0xb2
ffffffffc0203e4c:	8507a783          	lw	a5,-1968(a5) # ffffffffc02b5698 <nr_process>
{
ffffffffc0203e50:	7159                	addi	sp,sp,-112
ffffffffc0203e52:	e4ce                	sd	s3,72(sp)
ffffffffc0203e54:	f486                	sd	ra,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e56:	6985                	lui	s3,0x1
ffffffffc0203e58:	3737db63          	bge	a5,s3,ffffffffc02041ce <do_fork+0x386>
ffffffffc0203e5c:	f0a2                	sd	s0,96(sp)
ffffffffc0203e5e:	eca6                	sd	s1,88(sp)
ffffffffc0203e60:	e8ca                	sd	s2,80(sp)
ffffffffc0203e62:	e86a                	sd	s10,16(sp)
ffffffffc0203e64:	892e                	mv	s2,a1
ffffffffc0203e66:	84b2                	mv	s1,a2
ffffffffc0203e68:	8d2a                	mv	s10,a0
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
    // 1.创建进程结构体 
    if ((proc = alloc_proc()) == NULL)
ffffffffc0203e6a:	e4fff0ef          	jal	ffffffffc0203cb8 <alloc_proc>
ffffffffc0203e6e:	842a                	mv	s0,a0
ffffffffc0203e70:	2e050c63          	beqz	a0,ffffffffc0204168 <do_fork+0x320>
ffffffffc0203e74:	f45e                	sd	s7,40(sp)
    {
        goto fork_out;
    }
    // 设置父进程
    proc->parent = current;
ffffffffc0203e76:	000b2b97          	auipc	s7,0xb2
ffffffffc0203e7a:	82ab8b93          	addi	s7,s7,-2006 # ffffffffc02b56a0 <current>
ffffffffc0203e7e:	000bb783          	ld	a5,0(s7)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203e82:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0203e84:	f01c                	sd	a5,32(s0)
    current->wait_state = 0; // 确保父进程的wait_state为0 //////////+++
ffffffffc0203e86:	0e07a623          	sw	zero,236(a5)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203e8a:	f31fd0ef          	jal	ffffffffc0201dba <alloc_pages>
    if (page != NULL)
ffffffffc0203e8e:	2c050963          	beqz	a0,ffffffffc0204160 <do_fork+0x318>
ffffffffc0203e92:	e0d2                	sd	s4,64(sp)
    return page - pages + nbase;
ffffffffc0203e94:	000b1a17          	auipc	s4,0xb1
ffffffffc0203e98:	7fca0a13          	addi	s4,s4,2044 # ffffffffc02b5690 <pages>
ffffffffc0203e9c:	000a3783          	ld	a5,0(s4)
ffffffffc0203ea0:	fc56                	sd	s5,56(sp)
ffffffffc0203ea2:	00004a97          	auipc	s5,0x4
ffffffffc0203ea6:	29ea8a93          	addi	s5,s5,670 # ffffffffc0208140 <nbase>
ffffffffc0203eaa:	000ab703          	ld	a4,0(s5)
ffffffffc0203eae:	40f506b3          	sub	a3,a0,a5
ffffffffc0203eb2:	f85a                	sd	s6,48(sp)
    return KADDR(page2pa(page));
ffffffffc0203eb4:	000b1b17          	auipc	s6,0xb1
ffffffffc0203eb8:	7d4b0b13          	addi	s6,s6,2004 # ffffffffc02b5688 <npage>
ffffffffc0203ebc:	ec66                	sd	s9,24(sp)
    return page - pages + nbase;
ffffffffc0203ebe:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203ec0:	5cfd                	li	s9,-1
ffffffffc0203ec2:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc0203ec6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0203ec8:	00ccdc93          	srli	s9,s9,0xc
ffffffffc0203ecc:	0196f633          	and	a2,a3,s9
ffffffffc0203ed0:	f062                	sd	s8,32(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0203ed2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203ed4:	32f67763          	bgeu	a2,a5,ffffffffc0204202 <do_fork+0x3ba>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203ed8:	000bb603          	ld	a2,0(s7)
ffffffffc0203edc:	000b1b97          	auipc	s7,0xb1
ffffffffc0203ee0:	7a4b8b93          	addi	s7,s7,1956 # ffffffffc02b5680 <va_pa_offset>
ffffffffc0203ee4:	000bb783          	ld	a5,0(s7)
ffffffffc0203ee8:	02863c03          	ld	s8,40(a2)
ffffffffc0203eec:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203eee:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0203ef0:	020c0863          	beqz	s8,ffffffffc0203f20 <do_fork+0xd8>
    if (clone_flags & CLONE_VM)
ffffffffc0203ef4:	100d7793          	andi	a5,s10,256
ffffffffc0203ef8:	18078863          	beqz	a5,ffffffffc0204088 <do_fork+0x240>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203efc:	030c2703          	lw	a4,48(s8)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f00:	018c3783          	ld	a5,24(s8)
ffffffffc0203f04:	c02006b7          	lui	a3,0xc0200
ffffffffc0203f08:	2705                	addiw	a4,a4,1
ffffffffc0203f0a:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc0203f0e:	03843423          	sd	s8,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f12:	30d7e463          	bltu	a5,a3,ffffffffc020421a <do_fork+0x3d2>
ffffffffc0203f16:	000bb703          	ld	a4,0(s7)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f1a:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f1c:	8f99                	sub	a5,a5,a4
ffffffffc0203f1e:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f20:	6789                	lui	a5,0x2
ffffffffc0203f22:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7048>
ffffffffc0203f26:	96be                	add	a3,a3,a5
ffffffffc0203f28:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0203f2a:	87b6                	mv	a5,a3
ffffffffc0203f2c:	12048713          	addi	a4,s1,288
ffffffffc0203f30:	6890                	ld	a2,16(s1)
ffffffffc0203f32:	6088                	ld	a0,0(s1)
ffffffffc0203f34:	648c                	ld	a1,8(s1)
ffffffffc0203f36:	eb90                	sd	a2,16(a5)
ffffffffc0203f38:	e388                	sd	a0,0(a5)
ffffffffc0203f3a:	e78c                	sd	a1,8(a5)
ffffffffc0203f3c:	6c90                	ld	a2,24(s1)
ffffffffc0203f3e:	02048493          	addi	s1,s1,32
ffffffffc0203f42:	02078793          	addi	a5,a5,32
ffffffffc0203f46:	fec7bc23          	sd	a2,-8(a5)
ffffffffc0203f4a:	fee493e3          	bne	s1,a4,ffffffffc0203f30 <do_fork+0xe8>
    proc->tf->gpr.a0 = 0;
ffffffffc0203f4e:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203f52:	22090163          	beqz	s2,ffffffffc0204174 <do_fork+0x32c>
ffffffffc0203f56:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203f5a:	00000797          	auipc	a5,0x0
ffffffffc0203f5e:	df878793          	addi	a5,a5,-520 # ffffffffc0203d52 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203f62:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203f64:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f66:	100027f3          	csrr	a5,sstatus
ffffffffc0203f6a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f6c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f6e:	22079263          	bnez	a5,ffffffffc0204192 <do_fork+0x34a>
    if (++last_pid >= MAX_PID)
ffffffffc0203f72:	000ad517          	auipc	a0,0xad
ffffffffc0203f76:	27252503          	lw	a0,626(a0) # ffffffffc02b11e4 <last_pid.1>
ffffffffc0203f7a:	6789                	lui	a5,0x2
ffffffffc0203f7c:	2505                	addiw	a0,a0,1
ffffffffc0203f7e:	000ad717          	auipc	a4,0xad
ffffffffc0203f82:	26a72323          	sw	a0,614(a4) # ffffffffc02b11e4 <last_pid.1>
ffffffffc0203f86:	22f55563          	bge	a0,a5,ffffffffc02041b0 <do_fork+0x368>
    if (last_pid >= next_safe)
ffffffffc0203f8a:	000ad797          	auipc	a5,0xad
ffffffffc0203f8e:	2567a783          	lw	a5,598(a5) # ffffffffc02b11e0 <next_safe.0>
ffffffffc0203f92:	000b1497          	auipc	s1,0xb1
ffffffffc0203f96:	66e48493          	addi	s1,s1,1646 # ffffffffc02b5600 <proc_list>
ffffffffc0203f9a:	06f54563          	blt	a0,a5,ffffffffc0204004 <do_fork+0x1bc>
    return listelm->next;
ffffffffc0203f9e:	000b1497          	auipc	s1,0xb1
ffffffffc0203fa2:	66248493          	addi	s1,s1,1634 # ffffffffc02b5600 <proc_list>
ffffffffc0203fa6:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc0203faa:	6789                	lui	a5,0x2
ffffffffc0203fac:	000ad717          	auipc	a4,0xad
ffffffffc0203fb0:	22f72a23          	sw	a5,564(a4) # ffffffffc02b11e0 <next_safe.0>
ffffffffc0203fb4:	86aa                	mv	a3,a0
ffffffffc0203fb6:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0203fb8:	04988063          	beq	a7,s1,ffffffffc0203ff8 <do_fork+0x1b0>
ffffffffc0203fbc:	882e                	mv	a6,a1
ffffffffc0203fbe:	87c6                	mv	a5,a7
ffffffffc0203fc0:	6609                	lui	a2,0x2
ffffffffc0203fc2:	a811                	j	ffffffffc0203fd6 <do_fork+0x18e>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203fc4:	00e6d663          	bge	a3,a4,ffffffffc0203fd0 <do_fork+0x188>
ffffffffc0203fc8:	00c75463          	bge	a4,a2,ffffffffc0203fd0 <do_fork+0x188>
                next_safe = proc->pid;
ffffffffc0203fcc:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203fce:	4805                	li	a6,1
ffffffffc0203fd0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203fd2:	00978d63          	beq	a5,s1,ffffffffc0203fec <do_fork+0x1a4>
            if (proc->pid == last_pid)
ffffffffc0203fd6:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6fec>
ffffffffc0203fda:	fed715e3          	bne	a4,a3,ffffffffc0203fc4 <do_fork+0x17c>
                if (++last_pid >= next_safe)
ffffffffc0203fde:	2685                	addiw	a3,a3,1
ffffffffc0203fe0:	1ec6d163          	bge	a3,a2,ffffffffc02041c2 <do_fork+0x37a>
ffffffffc0203fe4:	679c                	ld	a5,8(a5)
ffffffffc0203fe6:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0203fe8:	fe9797e3          	bne	a5,s1,ffffffffc0203fd6 <do_fork+0x18e>
ffffffffc0203fec:	00080663          	beqz	a6,ffffffffc0203ff8 <do_fork+0x1b0>
ffffffffc0203ff0:	000ad797          	auipc	a5,0xad
ffffffffc0203ff4:	1ec7a823          	sw	a2,496(a5) # ffffffffc02b11e0 <next_safe.0>
ffffffffc0203ff8:	c591                	beqz	a1,ffffffffc0204004 <do_fork+0x1bc>
ffffffffc0203ffa:	000ad797          	auipc	a5,0xad
ffffffffc0203ffe:	1ed7a523          	sw	a3,490(a5) # ffffffffc02b11e4 <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204002:	8536                	mv	a0,a3
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        //    5. 设置进程状态为可运行
        // 分配唯一的PID
        proc->pid = get_pid();
ffffffffc0204004:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204006:	45a9                	li	a1,10
ffffffffc0204008:	3dc010ef          	jal	ffffffffc02053e4 <hash32>
ffffffffc020400c:	02051793          	slli	a5,a0,0x20
ffffffffc0204010:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204014:	000ad797          	auipc	a5,0xad
ffffffffc0204018:	5ec78793          	addi	a5,a5,1516 # ffffffffc02b1600 <hash_list>
ffffffffc020401c:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020401e:	6518                	ld	a4,8(a0)
ffffffffc0204020:	0d840793          	addi	a5,s0,216
ffffffffc0204024:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc0204026:	e31c                	sd	a5,0(a4)
ffffffffc0204028:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc020402a:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020402c:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204030:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc0204032:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0204034:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc0204036:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020403a:	7b74                	ld	a3,240(a4)
ffffffffc020403c:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc020403e:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc0204040:	e464                	sd	s1,200(s0)
ffffffffc0204042:	10d43023          	sd	a3,256(s0)
ffffffffc0204046:	c299                	beqz	a3,ffffffffc020404c <do_fork+0x204>
        proc->optr->yptr = proc;
ffffffffc0204048:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc020404a:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc020404c:	000b1797          	auipc	a5,0xb1
ffffffffc0204050:	64c7a783          	lw	a5,1612(a5) # ffffffffc02b5698 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204054:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc0204056:	2785                	addiw	a5,a5,1
ffffffffc0204058:	000b1717          	auipc	a4,0xb1
ffffffffc020405c:	64f72023          	sw	a5,1600(a4) # ffffffffc02b5698 <nr_process>
    if (flag)
ffffffffc0204060:	14091e63          	bnez	s2,ffffffffc02041bc <do_fork+0x374>
        set_links(proc); // 加入全局进程链表 //////////////+++
    }
    local_intr_restore(intr_flag);

    //   6. 设置进程状态为可运行
    wakeup_proc(proc);
ffffffffc0204064:	8522                	mv	a0,s0
ffffffffc0204066:	0d4010ef          	jal	ffffffffc020513a <wakeup_proc>

    // 7. 设置返回值为子进程的PID
    ret = proc->pid;
ffffffffc020406a:	4048                	lw	a0,4(s0)
ffffffffc020406c:	64e6                	ld	s1,88(sp)
ffffffffc020406e:	7406                	ld	s0,96(sp)
ffffffffc0204070:	6946                	ld	s2,80(sp)
ffffffffc0204072:	6a06                	ld	s4,64(sp)
ffffffffc0204074:	7ae2                	ld	s5,56(sp)
ffffffffc0204076:	7b42                	ld	s6,48(sp)
ffffffffc0204078:	7ba2                	ld	s7,40(sp)
ffffffffc020407a:	7c02                	ld	s8,32(sp)
ffffffffc020407c:	6ce2                	ld	s9,24(sp)
ffffffffc020407e:	6d42                	ld	s10,16(sp)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc0204080:	70a6                	ld	ra,104(sp)
ffffffffc0204082:	69a6                	ld	s3,72(sp)
ffffffffc0204084:	6165                	addi	sp,sp,112
ffffffffc0204086:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc0204088:	e43a                	sd	a4,8(sp)
ffffffffc020408a:	cf6ff0ef          	jal	ffffffffc0203580 <mm_create>
ffffffffc020408e:	8d2a                	mv	s10,a0
ffffffffc0204090:	c959                	beqz	a0,ffffffffc0204126 <do_fork+0x2de>
    if ((page = alloc_page()) == NULL)
ffffffffc0204092:	4505                	li	a0,1
ffffffffc0204094:	d27fd0ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc0204098:	c541                	beqz	a0,ffffffffc0204120 <do_fork+0x2d8>
    return page - pages + nbase;
ffffffffc020409a:	000a3683          	ld	a3,0(s4)
ffffffffc020409e:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc02040a0:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc02040a4:	40d506b3          	sub	a3,a0,a3
ffffffffc02040a8:	8699                	srai	a3,a3,0x6
ffffffffc02040aa:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02040ac:	0196fcb3          	and	s9,a3,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc02040b0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040b2:	14fcf863          	bgeu	s9,a5,ffffffffc0204202 <do_fork+0x3ba>
ffffffffc02040b6:	000bb783          	ld	a5,0(s7)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02040ba:	000b1597          	auipc	a1,0xb1
ffffffffc02040be:	5be5b583          	ld	a1,1470(a1) # ffffffffc02b5678 <boot_pgdir_va>
ffffffffc02040c2:	864e                	mv	a2,s3
ffffffffc02040c4:	00f689b3          	add	s3,a3,a5
ffffffffc02040c8:	854e                	mv	a0,s3
ffffffffc02040ca:	7c2010ef          	jal	ffffffffc020588c <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02040ce:	038c0c93          	addi	s9,s8,56
    mm->pgdir = pgdir;
ffffffffc02040d2:	013d3c23          	sd	s3,24(s10)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02040d6:	4785                	li	a5,1
ffffffffc02040d8:	40fcb7af          	amoor.d	a5,a5,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02040dc:	03f79713          	slli	a4,a5,0x3f
ffffffffc02040e0:	03f75793          	srli	a5,a4,0x3f
ffffffffc02040e4:	4985                	li	s3,1
ffffffffc02040e6:	cb91                	beqz	a5,ffffffffc02040fa <do_fork+0x2b2>
    {
        schedule();
ffffffffc02040e8:	14a010ef          	jal	ffffffffc0205232 <schedule>
ffffffffc02040ec:	413cb7af          	amoor.d	a5,s3,(s9)
    while (!try_lock(lock))
ffffffffc02040f0:	03f79713          	slli	a4,a5,0x3f
ffffffffc02040f4:	03f75793          	srli	a5,a4,0x3f
ffffffffc02040f8:	fbe5                	bnez	a5,ffffffffc02040e8 <do_fork+0x2a0>
        ret = dup_mmap(mm, oldmm);
ffffffffc02040fa:	85e2                	mv	a1,s8
ffffffffc02040fc:	856a                	mv	a0,s10
ffffffffc02040fe:	edeff0ef          	jal	ffffffffc02037dc <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204102:	57f9                	li	a5,-2
ffffffffc0204104:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc0204108:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020410a:	12078563          	beqz	a5,ffffffffc0204234 <do_fork+0x3ec>
    if ((mm = mm_create()) == NULL)
ffffffffc020410e:	8c6a                	mv	s8,s10
    if (ret != 0)
ffffffffc0204110:	de0506e3          	beqz	a0,ffffffffc0203efc <do_fork+0xb4>
    exit_mmap(mm);
ffffffffc0204114:	856a                	mv	a0,s10
ffffffffc0204116:	f5eff0ef          	jal	ffffffffc0203874 <exit_mmap>
    put_pgdir(mm);
ffffffffc020411a:	856a                	mv	a0,s10
ffffffffc020411c:	c45ff0ef          	jal	ffffffffc0203d60 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204120:	856a                	mv	a0,s10
ffffffffc0204122:	d9cff0ef          	jal	ffffffffc02036be <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204126:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204128:	c02007b7          	lui	a5,0xc0200
ffffffffc020412c:	0af6ef63          	bltu	a3,a5,ffffffffc02041ea <do_fork+0x3a2>
ffffffffc0204130:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage)
ffffffffc0204134:	000b3703          	ld	a4,0(s6)
    return pa2page(PADDR(kva));
ffffffffc0204138:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020413c:	83b1                	srli	a5,a5,0xc
ffffffffc020413e:	08e7fa63          	bgeu	a5,a4,ffffffffc02041d2 <do_fork+0x38a>
    return &pages[PPN(pa) - nbase];
ffffffffc0204142:	000ab703          	ld	a4,0(s5)
ffffffffc0204146:	000a3503          	ld	a0,0(s4)
ffffffffc020414a:	4589                	li	a1,2
ffffffffc020414c:	8f99                	sub	a5,a5,a4
ffffffffc020414e:	079a                	slli	a5,a5,0x6
ffffffffc0204150:	953e                	add	a0,a0,a5
ffffffffc0204152:	ca3fd0ef          	jal	ffffffffc0201df4 <free_pages>
}
ffffffffc0204156:	6a06                	ld	s4,64(sp)
ffffffffc0204158:	7ae2                	ld	s5,56(sp)
ffffffffc020415a:	7b42                	ld	s6,48(sp)
ffffffffc020415c:	7c02                	ld	s8,32(sp)
ffffffffc020415e:	6ce2                	ld	s9,24(sp)
    kfree(proc);
ffffffffc0204160:	8522                	mv	a0,s0
ffffffffc0204162:	b3dfd0ef          	jal	ffffffffc0201c9e <kfree>
ffffffffc0204166:	7ba2                	ld	s7,40(sp)
ffffffffc0204168:	7406                	ld	s0,96(sp)
ffffffffc020416a:	64e6                	ld	s1,88(sp)
ffffffffc020416c:	6946                	ld	s2,80(sp)
ffffffffc020416e:	6d42                	ld	s10,16(sp)
    ret = -E_NO_MEM;
ffffffffc0204170:	5571                	li	a0,-4
    return ret;
ffffffffc0204172:	b739                	j	ffffffffc0204080 <do_fork+0x238>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204174:	8936                	mv	s2,a3
ffffffffc0204176:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020417a:	00000797          	auipc	a5,0x0
ffffffffc020417e:	bd878793          	addi	a5,a5,-1064 # ffffffffc0203d52 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204182:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204184:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204186:	100027f3          	csrr	a5,sstatus
ffffffffc020418a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020418c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020418e:	de0782e3          	beqz	a5,ffffffffc0203f72 <do_fork+0x12a>
        intr_disable();
ffffffffc0204192:	f6cfc0ef          	jal	ffffffffc02008fe <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc0204196:	000ad517          	auipc	a0,0xad
ffffffffc020419a:	04e52503          	lw	a0,78(a0) # ffffffffc02b11e4 <last_pid.1>
ffffffffc020419e:	6789                	lui	a5,0x2
        return 1;
ffffffffc02041a0:	4905                	li	s2,1
ffffffffc02041a2:	2505                	addiw	a0,a0,1
ffffffffc02041a4:	000ad717          	auipc	a4,0xad
ffffffffc02041a8:	04a72023          	sw	a0,64(a4) # ffffffffc02b11e4 <last_pid.1>
ffffffffc02041ac:	dcf54fe3          	blt	a0,a5,ffffffffc0203f8a <do_fork+0x142>
        last_pid = 1;
ffffffffc02041b0:	4505                	li	a0,1
ffffffffc02041b2:	000ad797          	auipc	a5,0xad
ffffffffc02041b6:	02a7a923          	sw	a0,50(a5) # ffffffffc02b11e4 <last_pid.1>
        goto inside;
ffffffffc02041ba:	b3d5                	j	ffffffffc0203f9e <do_fork+0x156>
        intr_enable();
ffffffffc02041bc:	f3cfc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02041c0:	b555                	j	ffffffffc0204064 <do_fork+0x21c>
                    if (last_pid >= MAX_PID)
ffffffffc02041c2:	6789                	lui	a5,0x2
ffffffffc02041c4:	00f6c363          	blt	a3,a5,ffffffffc02041ca <do_fork+0x382>
                        last_pid = 1;
ffffffffc02041c8:	4685                	li	a3,1
                    goto repeat;
ffffffffc02041ca:	4585                	li	a1,1
ffffffffc02041cc:	b3f5                	j	ffffffffc0203fb8 <do_fork+0x170>
    int ret = -E_NO_FREE_PROC;
ffffffffc02041ce:	556d                	li	a0,-5
ffffffffc02041d0:	bd45                	j	ffffffffc0204080 <do_fork+0x238>
        panic("pa2page called with invalid pa");
ffffffffc02041d2:	00002617          	auipc	a2,0x2
ffffffffc02041d6:	55e60613          	addi	a2,a2,1374 # ffffffffc0206730 <etext+0xe8c>
ffffffffc02041da:	06900593          	li	a1,105
ffffffffc02041de:	00002517          	auipc	a0,0x2
ffffffffc02041e2:	4aa50513          	addi	a0,a0,1194 # ffffffffc0206688 <etext+0xde4>
ffffffffc02041e6:	a64fc0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc02041ea:	00002617          	auipc	a2,0x2
ffffffffc02041ee:	51e60613          	addi	a2,a2,1310 # ffffffffc0206708 <etext+0xe64>
ffffffffc02041f2:	07700593          	li	a1,119
ffffffffc02041f6:	00002517          	auipc	a0,0x2
ffffffffc02041fa:	49250513          	addi	a0,a0,1170 # ffffffffc0206688 <etext+0xde4>
ffffffffc02041fe:	a4cfc0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc0204202:	00002617          	auipc	a2,0x2
ffffffffc0204206:	45e60613          	addi	a2,a2,1118 # ffffffffc0206660 <etext+0xdbc>
ffffffffc020420a:	07100593          	li	a1,113
ffffffffc020420e:	00002517          	auipc	a0,0x2
ffffffffc0204212:	47a50513          	addi	a0,a0,1146 # ffffffffc0206688 <etext+0xde4>
ffffffffc0204216:	a34fc0ef          	jal	ffffffffc020044a <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020421a:	86be                	mv	a3,a5
ffffffffc020421c:	00002617          	auipc	a2,0x2
ffffffffc0204220:	4ec60613          	addi	a2,a2,1260 # ffffffffc0206708 <etext+0xe64>
ffffffffc0204224:	19f00593          	li	a1,415
ffffffffc0204228:	00003517          	auipc	a0,0x3
ffffffffc020422c:	e2050513          	addi	a0,a0,-480 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204230:	a1afc0ef          	jal	ffffffffc020044a <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204234:	00003617          	auipc	a2,0x3
ffffffffc0204238:	dec60613          	addi	a2,a2,-532 # ffffffffc0207020 <etext+0x177c>
ffffffffc020423c:	04000593          	li	a1,64
ffffffffc0204240:	00003517          	auipc	a0,0x3
ffffffffc0204244:	df050513          	addi	a0,a0,-528 # ffffffffc0207030 <etext+0x178c>
ffffffffc0204248:	a02fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc020424c <kernel_thread>:
{
ffffffffc020424c:	7129                	addi	sp,sp,-320
ffffffffc020424e:	fa22                	sd	s0,304(sp)
ffffffffc0204250:	f626                	sd	s1,296(sp)
ffffffffc0204252:	f24a                	sd	s2,288(sp)
ffffffffc0204254:	842a                	mv	s0,a0
ffffffffc0204256:	84ae                	mv	s1,a1
ffffffffc0204258:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020425a:	850a                	mv	a0,sp
ffffffffc020425c:	12000613          	li	a2,288
ffffffffc0204260:	4581                	li	a1,0
{
ffffffffc0204262:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204264:	616010ef          	jal	ffffffffc020587a <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204268:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020426a:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020426c:	100027f3          	csrr	a5,sstatus
ffffffffc0204270:	edd7f793          	andi	a5,a5,-291
ffffffffc0204274:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204278:	860a                	mv	a2,sp
ffffffffc020427a:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020427e:	00000717          	auipc	a4,0x0
ffffffffc0204282:	a3270713          	addi	a4,a4,-1486 # ffffffffc0203cb0 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204286:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204288:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020428a:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020428c:	bbdff0ef          	jal	ffffffffc0203e48 <do_fork>
}
ffffffffc0204290:	70f2                	ld	ra,312(sp)
ffffffffc0204292:	7452                	ld	s0,304(sp)
ffffffffc0204294:	74b2                	ld	s1,296(sp)
ffffffffc0204296:	7912                	ld	s2,288(sp)
ffffffffc0204298:	6131                	addi	sp,sp,320
ffffffffc020429a:	8082                	ret

ffffffffc020429c <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc020429c:	7179                	addi	sp,sp,-48
ffffffffc020429e:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02042a0:	000b1417          	auipc	s0,0xb1
ffffffffc02042a4:	40040413          	addi	s0,s0,1024 # ffffffffc02b56a0 <current>
ffffffffc02042a8:	601c                	ld	a5,0(s0)
ffffffffc02042aa:	000b1717          	auipc	a4,0xb1
ffffffffc02042ae:	40673703          	ld	a4,1030(a4) # ffffffffc02b56b0 <idleproc>
{
ffffffffc02042b2:	f406                	sd	ra,40(sp)
ffffffffc02042b4:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc02042b6:	0ce78b63          	beq	a5,a4,ffffffffc020438c <do_exit+0xf0>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc02042ba:	000b1497          	auipc	s1,0xb1
ffffffffc02042be:	3ee48493          	addi	s1,s1,1006 # ffffffffc02b56a8 <initproc>
ffffffffc02042c2:	6098                	ld	a4,0(s1)
ffffffffc02042c4:	e84a                	sd	s2,16(sp)
ffffffffc02042c6:	0ee78a63          	beq	a5,a4,ffffffffc02043ba <do_exit+0x11e>
ffffffffc02042ca:	892a                	mv	s2,a0
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc02042cc:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc02042ce:	c115                	beqz	a0,ffffffffc02042f2 <do_exit+0x56>
ffffffffc02042d0:	000b1797          	auipc	a5,0xb1
ffffffffc02042d4:	3a07b783          	ld	a5,928(a5) # ffffffffc02b5670 <boot_pgdir_pa>
ffffffffc02042d8:	577d                	li	a4,-1
ffffffffc02042da:	177e                	slli	a4,a4,0x3f
ffffffffc02042dc:	83b1                	srli	a5,a5,0xc
ffffffffc02042de:	8fd9                	or	a5,a5,a4
ffffffffc02042e0:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02042e4:	591c                	lw	a5,48(a0)
ffffffffc02042e6:	37fd                	addiw	a5,a5,-1
ffffffffc02042e8:	d91c                	sw	a5,48(a0)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc02042ea:	cfd5                	beqz	a5,ffffffffc02043a6 <do_exit+0x10a>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc02042ec:	601c                	ld	a5,0(s0)
ffffffffc02042ee:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc02042f2:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc02042f4:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02042f8:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02042fa:	100027f3          	csrr	a5,sstatus
ffffffffc02042fe:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204300:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204302:	ebe1                	bnez	a5,ffffffffc02043d2 <do_exit+0x136>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc0204304:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204306:	800007b7          	lui	a5,0x80000
ffffffffc020430a:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
        proc = current->parent;
ffffffffc020430c:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020430e:	0ec52703          	lw	a4,236(a0)
ffffffffc0204312:	0cf70463          	beq	a4,a5,ffffffffc02043da <do_exit+0x13e>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc0204316:	6018                	ld	a4,0(s0)
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204318:	800005b7          	lui	a1,0x80000
ffffffffc020431c:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
        while (current->cptr != NULL)
ffffffffc020431e:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204320:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc0204322:	e789                	bnez	a5,ffffffffc020432c <do_exit+0x90>
ffffffffc0204324:	a83d                	j	ffffffffc0204362 <do_exit+0xc6>
ffffffffc0204326:	6018                	ld	a4,0(s0)
ffffffffc0204328:	7b7c                	ld	a5,240(a4)
ffffffffc020432a:	cf85                	beqz	a5,ffffffffc0204362 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc020432c:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204330:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204332:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc0204334:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204338:	7978                	ld	a4,240(a0)
ffffffffc020433a:	10e7b023          	sd	a4,256(a5)
ffffffffc020433e:	c311                	beqz	a4,ffffffffc0204342 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc0204340:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204342:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204344:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204346:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204348:	fcc71fe3          	bne	a4,a2,ffffffffc0204326 <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020434c:	0ec52783          	lw	a5,236(a0)
ffffffffc0204350:	fcb79be3          	bne	a5,a1,ffffffffc0204326 <do_exit+0x8a>
                {
                    wakeup_proc(initproc);
ffffffffc0204354:	5e7000ef          	jal	ffffffffc020513a <wakeup_proc>
ffffffffc0204358:	800005b7          	lui	a1,0x80000
ffffffffc020435c:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
ffffffffc020435e:	460d                	li	a2,3
ffffffffc0204360:	b7d9                	j	ffffffffc0204326 <do_exit+0x8a>
    if (flag)
ffffffffc0204362:	02091263          	bnez	s2,ffffffffc0204386 <do_exit+0xea>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc0204366:	6cd000ef          	jal	ffffffffc0205232 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020436a:	601c                	ld	a5,0(s0)
ffffffffc020436c:	00003617          	auipc	a2,0x3
ffffffffc0204370:	d1460613          	addi	a2,a2,-748 # ffffffffc0207080 <etext+0x17dc>
ffffffffc0204374:	25b00593          	li	a1,603
ffffffffc0204378:	43d4                	lw	a3,4(a5)
ffffffffc020437a:	00003517          	auipc	a0,0x3
ffffffffc020437e:	cce50513          	addi	a0,a0,-818 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204382:	8c8fc0ef          	jal	ffffffffc020044a <__panic>
        intr_enable();
ffffffffc0204386:	d72fc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020438a:	bff1                	j	ffffffffc0204366 <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc020438c:	00003617          	auipc	a2,0x3
ffffffffc0204390:	cd460613          	addi	a2,a2,-812 # ffffffffc0207060 <etext+0x17bc>
ffffffffc0204394:	22700593          	li	a1,551
ffffffffc0204398:	00003517          	auipc	a0,0x3
ffffffffc020439c:	cb050513          	addi	a0,a0,-848 # ffffffffc0207048 <etext+0x17a4>
ffffffffc02043a0:	e84a                	sd	s2,16(sp)
ffffffffc02043a2:	8a8fc0ef          	jal	ffffffffc020044a <__panic>
            exit_mmap(mm);
ffffffffc02043a6:	e42a                	sd	a0,8(sp)
ffffffffc02043a8:	cccff0ef          	jal	ffffffffc0203874 <exit_mmap>
            put_pgdir(mm);
ffffffffc02043ac:	6522                	ld	a0,8(sp)
ffffffffc02043ae:	9b3ff0ef          	jal	ffffffffc0203d60 <put_pgdir>
            mm_destroy(mm);
ffffffffc02043b2:	6522                	ld	a0,8(sp)
ffffffffc02043b4:	b0aff0ef          	jal	ffffffffc02036be <mm_destroy>
ffffffffc02043b8:	bf15                	j	ffffffffc02042ec <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc02043ba:	00003617          	auipc	a2,0x3
ffffffffc02043be:	cb660613          	addi	a2,a2,-842 # ffffffffc0207070 <etext+0x17cc>
ffffffffc02043c2:	22b00593          	li	a1,555
ffffffffc02043c6:	00003517          	auipc	a0,0x3
ffffffffc02043ca:	c8250513          	addi	a0,a0,-894 # ffffffffc0207048 <etext+0x17a4>
ffffffffc02043ce:	87cfc0ef          	jal	ffffffffc020044a <__panic>
        intr_disable();
ffffffffc02043d2:	d2cfc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc02043d6:	4905                	li	s2,1
ffffffffc02043d8:	b735                	j	ffffffffc0204304 <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc02043da:	561000ef          	jal	ffffffffc020513a <wakeup_proc>
ffffffffc02043de:	bf25                	j	ffffffffc0204316 <do_exit+0x7a>

ffffffffc02043e0 <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc02043e0:	7179                	addi	sp,sp,-48
ffffffffc02043e2:	ec26                	sd	s1,24(sp)
ffffffffc02043e4:	e84a                	sd	s2,16(sp)
ffffffffc02043e6:	e44e                	sd	s3,8(sp)
ffffffffc02043e8:	f406                	sd	ra,40(sp)
ffffffffc02043ea:	f022                	sd	s0,32(sp)
ffffffffc02043ec:	84aa                	mv	s1,a0
ffffffffc02043ee:	892e                	mv	s2,a1
ffffffffc02043f0:	000b1997          	auipc	s3,0xb1
ffffffffc02043f4:	2b098993          	addi	s3,s3,688 # ffffffffc02b56a0 <current>

    struct proc_struct *proc;
    bool intr_flag, haskid;
repeat:
    haskid = 0;
    if (pid != 0)
ffffffffc02043f8:	cd19                	beqz	a0,ffffffffc0204416 <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc02043fa:	6789                	lui	a5,0x2
ffffffffc02043fc:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f2a>
ffffffffc02043fe:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204402:	12e7f563          	bgeu	a5,a4,ffffffffc020452c <do_wait.part.0+0x14c>
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc0204406:	70a2                	ld	ra,40(sp)
ffffffffc0204408:	7402                	ld	s0,32(sp)
ffffffffc020440a:	64e2                	ld	s1,24(sp)
ffffffffc020440c:	6942                	ld	s2,16(sp)
ffffffffc020440e:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204410:	5579                	li	a0,-2
}
ffffffffc0204412:	6145                	addi	sp,sp,48
ffffffffc0204414:	8082                	ret
        proc = current->cptr;
ffffffffc0204416:	0009b703          	ld	a4,0(s3)
ffffffffc020441a:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020441c:	d46d                	beqz	s0,ffffffffc0204406 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020441e:	468d                	li	a3,3
ffffffffc0204420:	a021                	j	ffffffffc0204428 <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204422:	10043403          	ld	s0,256(s0)
ffffffffc0204426:	c075                	beqz	s0,ffffffffc020450a <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204428:	401c                	lw	a5,0(s0)
ffffffffc020442a:	fed79ce3          	bne	a5,a3,ffffffffc0204422 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc020442e:	000b1797          	auipc	a5,0xb1
ffffffffc0204432:	2827b783          	ld	a5,642(a5) # ffffffffc02b56b0 <idleproc>
ffffffffc0204436:	14878263          	beq	a5,s0,ffffffffc020457a <do_wait.part.0+0x19a>
ffffffffc020443a:	000b1797          	auipc	a5,0xb1
ffffffffc020443e:	26e7b783          	ld	a5,622(a5) # ffffffffc02b56a8 <initproc>
ffffffffc0204442:	12f40c63          	beq	s0,a5,ffffffffc020457a <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc0204446:	00090663          	beqz	s2,ffffffffc0204452 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc020444a:	0e842783          	lw	a5,232(s0)
ffffffffc020444e:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204452:	100027f3          	csrr	a5,sstatus
ffffffffc0204456:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204458:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020445a:	10079963          	bnez	a5,ffffffffc020456c <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020445e:	6c74                	ld	a3,216(s0)
ffffffffc0204460:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc0204462:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc0204466:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204468:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020446a:	6474                	ld	a3,200(s0)
ffffffffc020446c:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc020446e:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204470:	e314                	sd	a3,0(a4)
ffffffffc0204472:	c789                	beqz	a5,ffffffffc020447c <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc0204474:	7c78                	ld	a4,248(s0)
ffffffffc0204476:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc0204478:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc020447c:	7c78                	ld	a4,248(s0)
ffffffffc020447e:	c36d                	beqz	a4,ffffffffc0204560 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc0204480:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc0204484:	000b1797          	auipc	a5,0xb1
ffffffffc0204488:	2147a783          	lw	a5,532(a5) # ffffffffc02b5698 <nr_process>
ffffffffc020448c:	37fd                	addiw	a5,a5,-1
ffffffffc020448e:	000b1717          	auipc	a4,0xb1
ffffffffc0204492:	20f72523          	sw	a5,522(a4) # ffffffffc02b5698 <nr_process>
    if (flag)
ffffffffc0204496:	e271                	bnez	a2,ffffffffc020455a <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204498:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020449a:	c02007b7          	lui	a5,0xc0200
ffffffffc020449e:	10f6e663          	bltu	a3,a5,ffffffffc02045aa <do_wait.part.0+0x1ca>
ffffffffc02044a2:	000b1717          	auipc	a4,0xb1
ffffffffc02044a6:	1de73703          	ld	a4,478(a4) # ffffffffc02b5680 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc02044aa:	000b1797          	auipc	a5,0xb1
ffffffffc02044ae:	1de7b783          	ld	a5,478(a5) # ffffffffc02b5688 <npage>
    return pa2page(PADDR(kva));
ffffffffc02044b2:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc02044b4:	82b1                	srli	a3,a3,0xc
ffffffffc02044b6:	0cf6fe63          	bgeu	a3,a5,ffffffffc0204592 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc02044ba:	00004797          	auipc	a5,0x4
ffffffffc02044be:	c867b783          	ld	a5,-890(a5) # ffffffffc0208140 <nbase>
ffffffffc02044c2:	000b1517          	auipc	a0,0xb1
ffffffffc02044c6:	1ce53503          	ld	a0,462(a0) # ffffffffc02b5690 <pages>
ffffffffc02044ca:	4589                	li	a1,2
ffffffffc02044cc:	8e9d                	sub	a3,a3,a5
ffffffffc02044ce:	069a                	slli	a3,a3,0x6
ffffffffc02044d0:	9536                	add	a0,a0,a3
ffffffffc02044d2:	923fd0ef          	jal	ffffffffc0201df4 <free_pages>
    kfree(proc);
ffffffffc02044d6:	8522                	mv	a0,s0
ffffffffc02044d8:	fc6fd0ef          	jal	ffffffffc0201c9e <kfree>
}
ffffffffc02044dc:	70a2                	ld	ra,40(sp)
ffffffffc02044de:	7402                	ld	s0,32(sp)
ffffffffc02044e0:	64e2                	ld	s1,24(sp)
ffffffffc02044e2:	6942                	ld	s2,16(sp)
ffffffffc02044e4:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc02044e6:	4501                	li	a0,0
}
ffffffffc02044e8:	6145                	addi	sp,sp,48
ffffffffc02044ea:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02044ec:	000b1997          	auipc	s3,0xb1
ffffffffc02044f0:	1b498993          	addi	s3,s3,436 # ffffffffc02b56a0 <current>
ffffffffc02044f4:	0009b703          	ld	a4,0(s3)
ffffffffc02044f8:	f487b683          	ld	a3,-184(a5)
ffffffffc02044fc:	f0e695e3          	bne	a3,a4,ffffffffc0204406 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204500:	f287a603          	lw	a2,-216(a5)
ffffffffc0204504:	468d                	li	a3,3
ffffffffc0204506:	06d60063          	beq	a2,a3,ffffffffc0204566 <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc020450a:	800007b7          	lui	a5,0x80000
ffffffffc020450e:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
        current->state = PROC_SLEEPING;
ffffffffc0204510:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc0204512:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc0204516:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc0204518:	51b000ef          	jal	ffffffffc0205232 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020451c:	0009b783          	ld	a5,0(s3)
ffffffffc0204520:	0b07a783          	lw	a5,176(a5)
ffffffffc0204524:	8b85                	andi	a5,a5,1
ffffffffc0204526:	e7b9                	bnez	a5,ffffffffc0204574 <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc0204528:	ee0487e3          	beqz	s1,ffffffffc0204416 <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020452c:	45a9                	li	a1,10
ffffffffc020452e:	8526                	mv	a0,s1
ffffffffc0204530:	6b5000ef          	jal	ffffffffc02053e4 <hash32>
ffffffffc0204534:	02051793          	slli	a5,a0,0x20
ffffffffc0204538:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020453c:	000ad797          	auipc	a5,0xad
ffffffffc0204540:	0c478793          	addi	a5,a5,196 # ffffffffc02b1600 <hash_list>
ffffffffc0204544:	953e                	add	a0,a0,a5
ffffffffc0204546:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204548:	a029                	j	ffffffffc0204552 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc020454a:	f2c7a703          	lw	a4,-212(a5)
ffffffffc020454e:	f8970fe3          	beq	a4,s1,ffffffffc02044ec <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc0204552:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204554:	fef51be3          	bne	a0,a5,ffffffffc020454a <do_wait.part.0+0x16a>
ffffffffc0204558:	b57d                	j	ffffffffc0204406 <do_wait.part.0+0x26>
        intr_enable();
ffffffffc020455a:	b9efc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020455e:	bf2d                	j	ffffffffc0204498 <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc0204560:	7018                	ld	a4,32(s0)
ffffffffc0204562:	fb7c                	sd	a5,240(a4)
ffffffffc0204564:	b705                	j	ffffffffc0204484 <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204566:	f2878413          	addi	s0,a5,-216
ffffffffc020456a:	b5d1                	j	ffffffffc020442e <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc020456c:	b92fc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0204570:	4605                	li	a2,1
ffffffffc0204572:	b5f5                	j	ffffffffc020445e <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc0204574:	555d                	li	a0,-9
ffffffffc0204576:	d27ff0ef          	jal	ffffffffc020429c <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc020457a:	00003617          	auipc	a2,0x3
ffffffffc020457e:	b2660613          	addi	a2,a2,-1242 # ffffffffc02070a0 <etext+0x17fc>
ffffffffc0204582:	37c00593          	li	a1,892
ffffffffc0204586:	00003517          	auipc	a0,0x3
ffffffffc020458a:	ac250513          	addi	a0,a0,-1342 # ffffffffc0207048 <etext+0x17a4>
ffffffffc020458e:	ebdfb0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204592:	00002617          	auipc	a2,0x2
ffffffffc0204596:	19e60613          	addi	a2,a2,414 # ffffffffc0206730 <etext+0xe8c>
ffffffffc020459a:	06900593          	li	a1,105
ffffffffc020459e:	00002517          	auipc	a0,0x2
ffffffffc02045a2:	0ea50513          	addi	a0,a0,234 # ffffffffc0206688 <etext+0xde4>
ffffffffc02045a6:	ea5fb0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc02045aa:	00002617          	auipc	a2,0x2
ffffffffc02045ae:	15e60613          	addi	a2,a2,350 # ffffffffc0206708 <etext+0xe64>
ffffffffc02045b2:	07700593          	li	a1,119
ffffffffc02045b6:	00002517          	auipc	a0,0x2
ffffffffc02045ba:	0d250513          	addi	a0,a0,210 # ffffffffc0206688 <etext+0xde4>
ffffffffc02045be:	e8dfb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02045c2 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02045c2:	1141                	addi	sp,sp,-16
ffffffffc02045c4:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02045c6:	867fd0ef          	jal	ffffffffc0201e2c <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02045ca:	e2afd0ef          	jal	ffffffffc0201bf4 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02045ce:	4601                	li	a2,0
ffffffffc02045d0:	4581                	li	a1,0
ffffffffc02045d2:	00000517          	auipc	a0,0x0
ffffffffc02045d6:	6b050513          	addi	a0,a0,1712 # ffffffffc0204c82 <user_main>
ffffffffc02045da:	c73ff0ef          	jal	ffffffffc020424c <kernel_thread>
    if (pid <= 0)
ffffffffc02045de:	00a04563          	bgtz	a0,ffffffffc02045e8 <init_main+0x26>
ffffffffc02045e2:	a071                	j	ffffffffc020466e <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02045e4:	44f000ef          	jal	ffffffffc0205232 <schedule>
    if (code_store != NULL)
ffffffffc02045e8:	4581                	li	a1,0
ffffffffc02045ea:	4501                	li	a0,0
ffffffffc02045ec:	df5ff0ef          	jal	ffffffffc02043e0 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02045f0:	d975                	beqz	a0,ffffffffc02045e4 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02045f2:	00003517          	auipc	a0,0x3
ffffffffc02045f6:	aee50513          	addi	a0,a0,-1298 # ffffffffc02070e0 <etext+0x183c>
ffffffffc02045fa:	b9ffb0ef          	jal	ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02045fe:	000b1797          	auipc	a5,0xb1
ffffffffc0204602:	0aa7b783          	ld	a5,170(a5) # ffffffffc02b56a8 <initproc>
ffffffffc0204606:	7bf8                	ld	a4,240(a5)
ffffffffc0204608:	e339                	bnez	a4,ffffffffc020464e <init_main+0x8c>
ffffffffc020460a:	7ff8                	ld	a4,248(a5)
ffffffffc020460c:	e329                	bnez	a4,ffffffffc020464e <init_main+0x8c>
ffffffffc020460e:	1007b703          	ld	a4,256(a5)
ffffffffc0204612:	ef15                	bnez	a4,ffffffffc020464e <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204614:	000b1697          	auipc	a3,0xb1
ffffffffc0204618:	0846a683          	lw	a3,132(a3) # ffffffffc02b5698 <nr_process>
ffffffffc020461c:	4709                	li	a4,2
ffffffffc020461e:	0ae69463          	bne	a3,a4,ffffffffc02046c6 <init_main+0x104>
ffffffffc0204622:	000b1697          	auipc	a3,0xb1
ffffffffc0204626:	fde68693          	addi	a3,a3,-34 # ffffffffc02b5600 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020462a:	6698                	ld	a4,8(a3)
ffffffffc020462c:	0c878793          	addi	a5,a5,200
ffffffffc0204630:	06f71b63          	bne	a4,a5,ffffffffc02046a6 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204634:	629c                	ld	a5,0(a3)
ffffffffc0204636:	04f71863          	bne	a4,a5,ffffffffc0204686 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc020463a:	00003517          	auipc	a0,0x3
ffffffffc020463e:	b8e50513          	addi	a0,a0,-1138 # ffffffffc02071c8 <etext+0x1924>
ffffffffc0204642:	b57fb0ef          	jal	ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc0204646:	60a2                	ld	ra,8(sp)
ffffffffc0204648:	4501                	li	a0,0
ffffffffc020464a:	0141                	addi	sp,sp,16
ffffffffc020464c:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020464e:	00003697          	auipc	a3,0x3
ffffffffc0204652:	aba68693          	addi	a3,a3,-1350 # ffffffffc0207108 <etext+0x1864>
ffffffffc0204656:	00002617          	auipc	a2,0x2
ffffffffc020465a:	c5a60613          	addi	a2,a2,-934 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc020465e:	3e800593          	li	a1,1000
ffffffffc0204662:	00003517          	auipc	a0,0x3
ffffffffc0204666:	9e650513          	addi	a0,a0,-1562 # ffffffffc0207048 <etext+0x17a4>
ffffffffc020466a:	de1fb0ef          	jal	ffffffffc020044a <__panic>
        panic("create user_main failed.\n");
ffffffffc020466e:	00003617          	auipc	a2,0x3
ffffffffc0204672:	a5260613          	addi	a2,a2,-1454 # ffffffffc02070c0 <etext+0x181c>
ffffffffc0204676:	3df00593          	li	a1,991
ffffffffc020467a:	00003517          	auipc	a0,0x3
ffffffffc020467e:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204682:	dc9fb0ef          	jal	ffffffffc020044a <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204686:	00003697          	auipc	a3,0x3
ffffffffc020468a:	b1268693          	addi	a3,a3,-1262 # ffffffffc0207198 <etext+0x18f4>
ffffffffc020468e:	00002617          	auipc	a2,0x2
ffffffffc0204692:	c2260613          	addi	a2,a2,-990 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0204696:	3eb00593          	li	a1,1003
ffffffffc020469a:	00003517          	auipc	a0,0x3
ffffffffc020469e:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0207048 <etext+0x17a4>
ffffffffc02046a2:	da9fb0ef          	jal	ffffffffc020044a <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02046a6:	00003697          	auipc	a3,0x3
ffffffffc02046aa:	ac268693          	addi	a3,a3,-1342 # ffffffffc0207168 <etext+0x18c4>
ffffffffc02046ae:	00002617          	auipc	a2,0x2
ffffffffc02046b2:	c0260613          	addi	a2,a2,-1022 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02046b6:	3ea00593          	li	a1,1002
ffffffffc02046ba:	00003517          	auipc	a0,0x3
ffffffffc02046be:	98e50513          	addi	a0,a0,-1650 # ffffffffc0207048 <etext+0x17a4>
ffffffffc02046c2:	d89fb0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_process == 2);
ffffffffc02046c6:	00003697          	auipc	a3,0x3
ffffffffc02046ca:	a9268693          	addi	a3,a3,-1390 # ffffffffc0207158 <etext+0x18b4>
ffffffffc02046ce:	00002617          	auipc	a2,0x2
ffffffffc02046d2:	be260613          	addi	a2,a2,-1054 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc02046d6:	3e900593          	li	a1,1001
ffffffffc02046da:	00003517          	auipc	a0,0x3
ffffffffc02046de:	96e50513          	addi	a0,a0,-1682 # ffffffffc0207048 <etext+0x17a4>
ffffffffc02046e2:	d69fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02046e6 <do_execve>:
{
ffffffffc02046e6:	7171                	addi	sp,sp,-176
ffffffffc02046e8:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02046ea:	000b1d17          	auipc	s10,0xb1
ffffffffc02046ee:	fb6d0d13          	addi	s10,s10,-74 # ffffffffc02b56a0 <current>
ffffffffc02046f2:	000d3783          	ld	a5,0(s10)
{
ffffffffc02046f6:	e94a                	sd	s2,144(sp)
ffffffffc02046f8:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02046fa:	0287b903          	ld	s2,40(a5)
{
ffffffffc02046fe:	84ae                	mv	s1,a1
ffffffffc0204700:	e54e                	sd	s3,136(sp)
ffffffffc0204702:	ec32                	sd	a2,24(sp)
ffffffffc0204704:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204706:	85aa                	mv	a1,a0
ffffffffc0204708:	8626                	mv	a2,s1
ffffffffc020470a:	854a                	mv	a0,s2
ffffffffc020470c:	4681                	li	a3,0
{
ffffffffc020470e:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204710:	cfcff0ef          	jal	ffffffffc0203c0c <user_mem_check>
ffffffffc0204714:	46050f63          	beqz	a0,ffffffffc0204b92 <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204718:	4641                	li	a2,16
ffffffffc020471a:	1808                	addi	a0,sp,48
ffffffffc020471c:	4581                	li	a1,0
ffffffffc020471e:	15c010ef          	jal	ffffffffc020587a <memset>
    if (len > PROC_NAME_LEN)
ffffffffc0204722:	47bd                	li	a5,15
ffffffffc0204724:	8626                	mv	a2,s1
ffffffffc0204726:	0e97ef63          	bltu	a5,s1,ffffffffc0204824 <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc020472a:	85ce                	mv	a1,s3
ffffffffc020472c:	1808                	addi	a0,sp,48
ffffffffc020472e:	15e010ef          	jal	ffffffffc020588c <memcpy>
    if (mm != NULL)
ffffffffc0204732:	10090063          	beqz	s2,ffffffffc0204832 <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc0204736:	00002517          	auipc	a0,0x2
ffffffffc020473a:	71250513          	addi	a0,a0,1810 # ffffffffc0206e48 <etext+0x15a4>
ffffffffc020473e:	a91fb0ef          	jal	ffffffffc02001ce <cputs>
ffffffffc0204742:	000b1797          	auipc	a5,0xb1
ffffffffc0204746:	f2e7b783          	ld	a5,-210(a5) # ffffffffc02b5670 <boot_pgdir_pa>
ffffffffc020474a:	577d                	li	a4,-1
ffffffffc020474c:	177e                	slli	a4,a4,0x3f
ffffffffc020474e:	83b1                	srli	a5,a5,0xc
ffffffffc0204750:	8fd9                	or	a5,a5,a4
ffffffffc0204752:	18079073          	csrw	satp,a5
ffffffffc0204756:	03092783          	lw	a5,48(s2)
ffffffffc020475a:	37fd                	addiw	a5,a5,-1
ffffffffc020475c:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204760:	30078563          	beqz	a5,ffffffffc0204a6a <do_execve+0x384>
        current->mm = NULL;
ffffffffc0204764:	000d3783          	ld	a5,0(s10)
ffffffffc0204768:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc020476c:	e15fe0ef          	jal	ffffffffc0203580 <mm_create>
ffffffffc0204770:	892a                	mv	s2,a0
ffffffffc0204772:	22050063          	beqz	a0,ffffffffc0204992 <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc0204776:	4505                	li	a0,1
ffffffffc0204778:	e42fd0ef          	jal	ffffffffc0201dba <alloc_pages>
ffffffffc020477c:	42050063          	beqz	a0,ffffffffc0204b9c <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc0204780:	f0e2                	sd	s8,96(sp)
ffffffffc0204782:	000b1c17          	auipc	s8,0xb1
ffffffffc0204786:	f0ec0c13          	addi	s8,s8,-242 # ffffffffc02b5690 <pages>
ffffffffc020478a:	000c3783          	ld	a5,0(s8)
ffffffffc020478e:	f4de                	sd	s7,104(sp)
ffffffffc0204790:	00004b97          	auipc	s7,0x4
ffffffffc0204794:	9b0bbb83          	ld	s7,-1616(s7) # ffffffffc0208140 <nbase>
ffffffffc0204798:	40f506b3          	sub	a3,a0,a5
ffffffffc020479c:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc020479e:	000b1c97          	auipc	s9,0xb1
ffffffffc02047a2:	eeac8c93          	addi	s9,s9,-278 # ffffffffc02b5688 <npage>
ffffffffc02047a6:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc02047a8:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02047aa:	5b7d                	li	s6,-1
ffffffffc02047ac:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc02047b0:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02047b2:	00cb5713          	srli	a4,s6,0xc
ffffffffc02047b6:	e83a                	sd	a4,16(sp)
ffffffffc02047b8:	fcd6                	sd	s5,120(sp)
ffffffffc02047ba:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02047bc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02047be:	40f77263          	bgeu	a4,a5,ffffffffc0204bc2 <do_execve+0x4dc>
ffffffffc02047c2:	000b1a97          	auipc	s5,0xb1
ffffffffc02047c6:	ebea8a93          	addi	s5,s5,-322 # ffffffffc02b5680 <va_pa_offset>
ffffffffc02047ca:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02047ce:	000b1597          	auipc	a1,0xb1
ffffffffc02047d2:	eaa5b583          	ld	a1,-342(a1) # ffffffffc02b5678 <boot_pgdir_va>
ffffffffc02047d6:	6605                	lui	a2,0x1
ffffffffc02047d8:	00f684b3          	add	s1,a3,a5
ffffffffc02047dc:	8526                	mv	a0,s1
ffffffffc02047de:	0ae010ef          	jal	ffffffffc020588c <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02047e2:	66e2                	ld	a3,24(sp)
ffffffffc02047e4:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02047e8:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02047ec:	4298                	lw	a4,0(a3)
ffffffffc02047ee:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b903f>
ffffffffc02047f2:	06f70863          	beq	a4,a5,ffffffffc0204862 <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc02047f6:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc02047f8:	854a                	mv	a0,s2
ffffffffc02047fa:	d66ff0ef          	jal	ffffffffc0203d60 <put_pgdir>
ffffffffc02047fe:	7ae6                	ld	s5,120(sp)
ffffffffc0204800:	7b46                	ld	s6,112(sp)
ffffffffc0204802:	7ba6                	ld	s7,104(sp)
ffffffffc0204804:	7c06                	ld	s8,96(sp)
ffffffffc0204806:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc0204808:	854a                	mv	a0,s2
ffffffffc020480a:	eb5fe0ef          	jal	ffffffffc02036be <mm_destroy>
    do_exit(ret);
ffffffffc020480e:	8526                	mv	a0,s1
ffffffffc0204810:	f122                	sd	s0,160(sp)
ffffffffc0204812:	e152                	sd	s4,128(sp)
ffffffffc0204814:	fcd6                	sd	s5,120(sp)
ffffffffc0204816:	f8da                	sd	s6,112(sp)
ffffffffc0204818:	f4de                	sd	s7,104(sp)
ffffffffc020481a:	f0e2                	sd	s8,96(sp)
ffffffffc020481c:	ece6                	sd	s9,88(sp)
ffffffffc020481e:	e4ee                	sd	s11,72(sp)
ffffffffc0204820:	a7dff0ef          	jal	ffffffffc020429c <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204824:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc0204826:	85ce                	mv	a1,s3
ffffffffc0204828:	1808                	addi	a0,sp,48
ffffffffc020482a:	062010ef          	jal	ffffffffc020588c <memcpy>
    if (mm != NULL)
ffffffffc020482e:	f00914e3          	bnez	s2,ffffffffc0204736 <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204832:	000d3783          	ld	a5,0(s10)
ffffffffc0204836:	779c                	ld	a5,40(a5)
ffffffffc0204838:	db95                	beqz	a5,ffffffffc020476c <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc020483a:	00003617          	auipc	a2,0x3
ffffffffc020483e:	9ae60613          	addi	a2,a2,-1618 # ffffffffc02071e8 <etext+0x1944>
ffffffffc0204842:	26700593          	li	a1,615
ffffffffc0204846:	00003517          	auipc	a0,0x3
ffffffffc020484a:	80250513          	addi	a0,a0,-2046 # ffffffffc0207048 <etext+0x17a4>
ffffffffc020484e:	f122                	sd	s0,160(sp)
ffffffffc0204850:	e152                	sd	s4,128(sp)
ffffffffc0204852:	fcd6                	sd	s5,120(sp)
ffffffffc0204854:	f8da                	sd	s6,112(sp)
ffffffffc0204856:	f4de                	sd	s7,104(sp)
ffffffffc0204858:	f0e2                	sd	s8,96(sp)
ffffffffc020485a:	ece6                	sd	s9,88(sp)
ffffffffc020485c:	e4ee                	sd	s11,72(sp)
ffffffffc020485e:	bedfb0ef          	jal	ffffffffc020044a <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204862:	0386d703          	lhu	a4,56(a3)
ffffffffc0204866:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204868:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020486c:	00371793          	slli	a5,a4,0x3
ffffffffc0204870:	8f99                	sub	a5,a5,a4
ffffffffc0204872:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204874:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204876:	97d2                	add	a5,a5,s4
ffffffffc0204878:	f122                	sd	s0,160(sp)
ffffffffc020487a:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc020487c:	00fa7e63          	bgeu	s4,a5,ffffffffc0204898 <do_execve+0x1b2>
ffffffffc0204880:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204882:	000a2783          	lw	a5,0(s4)
ffffffffc0204886:	4705                	li	a4,1
ffffffffc0204888:	10e78763          	beq	a5,a4,ffffffffc0204996 <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc020488c:	77a2                	ld	a5,40(sp)
ffffffffc020488e:	038a0a13          	addi	s4,s4,56
ffffffffc0204892:	fefa68e3          	bltu	s4,a5,ffffffffc0204882 <do_execve+0x19c>
ffffffffc0204896:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204898:	4701                	li	a4,0
ffffffffc020489a:	46ad                	li	a3,11
ffffffffc020489c:	00100637          	lui	a2,0x100
ffffffffc02048a0:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02048a4:	854a                	mv	a0,s2
ffffffffc02048a6:	e6bfe0ef          	jal	ffffffffc0203710 <mm_map>
ffffffffc02048aa:	84aa                	mv	s1,a0
ffffffffc02048ac:	1a051963          	bnez	a0,ffffffffc0204a5e <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02048b0:	01893503          	ld	a0,24(s2)
ffffffffc02048b4:	467d                	li	a2,31
ffffffffc02048b6:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02048ba:	be5fe0ef          	jal	ffffffffc020349e <pgdir_alloc_page>
ffffffffc02048be:	3a050163          	beqz	a0,ffffffffc0204c60 <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048c2:	01893503          	ld	a0,24(s2)
ffffffffc02048c6:	467d                	li	a2,31
ffffffffc02048c8:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02048cc:	bd3fe0ef          	jal	ffffffffc020349e <pgdir_alloc_page>
ffffffffc02048d0:	36050763          	beqz	a0,ffffffffc0204c3e <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048d4:	01893503          	ld	a0,24(s2)
ffffffffc02048d8:	467d                	li	a2,31
ffffffffc02048da:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02048de:	bc1fe0ef          	jal	ffffffffc020349e <pgdir_alloc_page>
ffffffffc02048e2:	32050d63          	beqz	a0,ffffffffc0204c1c <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048e6:	01893503          	ld	a0,24(s2)
ffffffffc02048ea:	467d                	li	a2,31
ffffffffc02048ec:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02048f0:	baffe0ef          	jal	ffffffffc020349e <pgdir_alloc_page>
ffffffffc02048f4:	30050363          	beqz	a0,ffffffffc0204bfa <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc02048f8:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc02048fc:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204900:	01893683          	ld	a3,24(s2)
ffffffffc0204904:	2785                	addiw	a5,a5,1
ffffffffc0204906:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc020490a:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_matrix_out_size+0xf4ae8>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020490e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204912:	2cf6e763          	bltu	a3,a5,ffffffffc0204be0 <do_execve+0x4fa>
ffffffffc0204916:	000ab783          	ld	a5,0(s5)
ffffffffc020491a:	577d                	li	a4,-1
ffffffffc020491c:	177e                	slli	a4,a4,0x3f
ffffffffc020491e:	8e9d                	sub	a3,a3,a5
ffffffffc0204920:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204924:	f654                	sd	a3,168(a2)
ffffffffc0204926:	8fd9                	or	a5,a5,a4
ffffffffc0204928:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc020492c:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc020492e:	4581                	li	a1,0
ffffffffc0204930:	12000613          	li	a2,288
ffffffffc0204934:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204936:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc020493a:	741000ef          	jal	ffffffffc020587a <memset>
    tf->epc = elf->e_entry; // 设置程序计数器
ffffffffc020493e:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204940:	000d3983          	ld	s3,0(s10)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
ffffffffc0204944:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry; // 设置程序计数器
ffffffffc0204948:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP; // 设置用户栈顶指针
ffffffffc020494a:	4785                	li	a5,1
ffffffffc020494c:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
ffffffffc020494e:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry; // 设置程序计数器
ffffffffc0204952:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP; // 设置用户栈顶指针
ffffffffc0204956:	e81c                	sd	a5,16(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
ffffffffc0204958:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020495c:	4641                	li	a2,16
ffffffffc020495e:	4581                	li	a1,0
ffffffffc0204960:	0b498513          	addi	a0,s3,180
ffffffffc0204964:	717000ef          	jal	ffffffffc020587a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204968:	180c                	addi	a1,sp,48
ffffffffc020496a:	0b498513          	addi	a0,s3,180
ffffffffc020496e:	463d                	li	a2,15
ffffffffc0204970:	71d000ef          	jal	ffffffffc020588c <memcpy>
ffffffffc0204974:	740a                	ld	s0,160(sp)
ffffffffc0204976:	6a0a                	ld	s4,128(sp)
ffffffffc0204978:	7ae6                	ld	s5,120(sp)
ffffffffc020497a:	7b46                	ld	s6,112(sp)
ffffffffc020497c:	7ba6                	ld	s7,104(sp)
ffffffffc020497e:	7c06                	ld	s8,96(sp)
ffffffffc0204980:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204982:	70aa                	ld	ra,168(sp)
ffffffffc0204984:	694a                	ld	s2,144(sp)
ffffffffc0204986:	69aa                	ld	s3,136(sp)
ffffffffc0204988:	6d46                	ld	s10,80(sp)
ffffffffc020498a:	8526                	mv	a0,s1
ffffffffc020498c:	64ea                	ld	s1,152(sp)
ffffffffc020498e:	614d                	addi	sp,sp,176
ffffffffc0204990:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204992:	54f1                	li	s1,-4
ffffffffc0204994:	bdad                	j	ffffffffc020480e <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204996:	028a3603          	ld	a2,40(s4)
ffffffffc020499a:	020a3783          	ld	a5,32(s4)
ffffffffc020499e:	20f66363          	bltu	a2,a5,ffffffffc0204ba4 <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc02049a2:	004a2783          	lw	a5,4(s4)
ffffffffc02049a6:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049aa:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc02049ae:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049b0:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049b2:	c6f1                	beqz	a3,ffffffffc0204a7e <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049b4:	1c079763          	bnez	a5,ffffffffc0204b82 <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc02049b8:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc02049ba:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc02049be:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc02049c0:	c709                	beqz	a4,ffffffffc02049ca <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc02049c2:	67a2                	ld	a5,8(sp)
ffffffffc02049c4:	0087e793          	ori	a5,a5,8
ffffffffc02049c8:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc02049ca:	010a3583          	ld	a1,16(s4)
ffffffffc02049ce:	4701                	li	a4,0
ffffffffc02049d0:	854a                	mv	a0,s2
ffffffffc02049d2:	d3ffe0ef          	jal	ffffffffc0203710 <mm_map>
ffffffffc02049d6:	84aa                	mv	s1,a0
ffffffffc02049d8:	1c051463          	bnez	a0,ffffffffc0204ba0 <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049dc:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc02049e0:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049e4:	77fd                	lui	a5,0xfffff
ffffffffc02049e6:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc02049ea:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc02049ec:	1a9b7563          	bgeu	s6,s1,ffffffffc0204b96 <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049f0:	008a3983          	ld	s3,8(s4)
ffffffffc02049f4:	67e2                	ld	a5,24(sp)
ffffffffc02049f6:	99be                	add	s3,s3,a5
ffffffffc02049f8:	a881                	j	ffffffffc0204a48 <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc02049fa:	6785                	lui	a5,0x1
ffffffffc02049fc:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204a00:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204a04:	01b4e463          	bltu	s1,s11,ffffffffc0204a0c <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204a08:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204a0c:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204a10:	67c2                	ld	a5,16(sp)
ffffffffc0204a12:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204a16:	40d406b3          	sub	a3,s0,a3
ffffffffc0204a1a:	8699                	srai	a3,a3,0x6
ffffffffc0204a1c:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204a1e:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a22:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a24:	18a87363          	bgeu	a6,a0,ffffffffc0204baa <do_execve+0x4c4>
ffffffffc0204a28:	000ab503          	ld	a0,0(s5)
ffffffffc0204a2c:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a30:	e032                	sd	a2,0(sp)
ffffffffc0204a32:	9536                	add	a0,a0,a3
ffffffffc0204a34:	952e                	add	a0,a0,a1
ffffffffc0204a36:	85ce                	mv	a1,s3
ffffffffc0204a38:	655000ef          	jal	ffffffffc020588c <memcpy>
            start += size, from += size;
ffffffffc0204a3c:	6602                	ld	a2,0(sp)
ffffffffc0204a3e:	9b32                	add	s6,s6,a2
ffffffffc0204a40:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204a42:	049b7563          	bgeu	s6,s1,ffffffffc0204a8c <do_execve+0x3a6>
ffffffffc0204a46:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204a48:	01893503          	ld	a0,24(s2)
ffffffffc0204a4c:	6622                	ld	a2,8(sp)
ffffffffc0204a4e:	e02e                	sd	a1,0(sp)
ffffffffc0204a50:	a4ffe0ef          	jal	ffffffffc020349e <pgdir_alloc_page>
ffffffffc0204a54:	6582                	ld	a1,0(sp)
ffffffffc0204a56:	842a                	mv	s0,a0
ffffffffc0204a58:	f14d                	bnez	a0,ffffffffc02049fa <do_execve+0x314>
ffffffffc0204a5a:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204a5c:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204a5e:	854a                	mv	a0,s2
ffffffffc0204a60:	e15fe0ef          	jal	ffffffffc0203874 <exit_mmap>
ffffffffc0204a64:	740a                	ld	s0,160(sp)
ffffffffc0204a66:	6a0a                	ld	s4,128(sp)
ffffffffc0204a68:	bb41                	j	ffffffffc02047f8 <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204a6a:	854a                	mv	a0,s2
ffffffffc0204a6c:	e09fe0ef          	jal	ffffffffc0203874 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204a70:	854a                	mv	a0,s2
ffffffffc0204a72:	aeeff0ef          	jal	ffffffffc0203d60 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204a76:	854a                	mv	a0,s2
ffffffffc0204a78:	c47fe0ef          	jal	ffffffffc02036be <mm_destroy>
ffffffffc0204a7c:	b1e5                	j	ffffffffc0204764 <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a7e:	0e078e63          	beqz	a5,ffffffffc0204b7a <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204a82:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204a84:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204a88:	e43e                	sd	a5,8(sp)
ffffffffc0204a8a:	bf1d                	j	ffffffffc02049c0 <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204a8c:	010a3483          	ld	s1,16(s4)
ffffffffc0204a90:	028a3683          	ld	a3,40(s4)
ffffffffc0204a94:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204a96:	07bb7c63          	bgeu	s6,s11,ffffffffc0204b0e <do_execve+0x428>
            if (start == end)
ffffffffc0204a9a:	df6489e3          	beq	s1,s6,ffffffffc020488c <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204a9e:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204aa2:	0fb4f563          	bgeu	s1,s11,ffffffffc0204b8c <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204aa6:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204aaa:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204aae:	40d406b3          	sub	a3,s0,a3
ffffffffc0204ab2:	8699                	srai	a3,a3,0x6
ffffffffc0204ab4:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204ab6:	00c69593          	slli	a1,a3,0xc
ffffffffc0204aba:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204abc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204abe:	0ec5f663          	bgeu	a1,a2,ffffffffc0204baa <do_execve+0x4c4>
ffffffffc0204ac2:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204ac6:	6505                	lui	a0,0x1
ffffffffc0204ac8:	955a                	add	a0,a0,s6
ffffffffc0204aca:	96b2                	add	a3,a3,a2
ffffffffc0204acc:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ad0:	9536                	add	a0,a0,a3
ffffffffc0204ad2:	864e                	mv	a2,s3
ffffffffc0204ad4:	4581                	li	a1,0
ffffffffc0204ad6:	5a5000ef          	jal	ffffffffc020587a <memset>
            start += size;
ffffffffc0204ada:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204adc:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204ae0:	01b4f463          	bgeu	s1,s11,ffffffffc0204ae8 <do_execve+0x402>
ffffffffc0204ae4:	db6484e3          	beq	s1,s6,ffffffffc020488c <do_execve+0x1a6>
ffffffffc0204ae8:	e299                	bnez	a3,ffffffffc0204aee <do_execve+0x408>
ffffffffc0204aea:	03bb0263          	beq	s6,s11,ffffffffc0204b0e <do_execve+0x428>
ffffffffc0204aee:	00002697          	auipc	a3,0x2
ffffffffc0204af2:	72268693          	addi	a3,a3,1826 # ffffffffc0207210 <etext+0x196c>
ffffffffc0204af6:	00001617          	auipc	a2,0x1
ffffffffc0204afa:	7ba60613          	addi	a2,a2,1978 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0204afe:	2d000593          	li	a1,720
ffffffffc0204b02:	00002517          	auipc	a0,0x2
ffffffffc0204b06:	54650513          	addi	a0,a0,1350 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204b0a:	941fb0ef          	jal	ffffffffc020044a <__panic>
        while (start < end)
ffffffffc0204b0e:	d69b7fe3          	bgeu	s6,s1,ffffffffc020488c <do_execve+0x1a6>
ffffffffc0204b12:	56fd                	li	a3,-1
ffffffffc0204b14:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b18:	f03e                	sd	a5,32(sp)
ffffffffc0204b1a:	a0b9                	j	ffffffffc0204b68 <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b1c:	6785                	lui	a5,0x1
ffffffffc0204b1e:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204b22:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204b26:	0104e463          	bltu	s1,a6,ffffffffc0204b2e <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b2a:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204b2e:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204b32:	7782                	ld	a5,32(sp)
ffffffffc0204b34:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204b38:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b3c:	8699                	srai	a3,a3,0x6
ffffffffc0204b3e:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204b40:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b44:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b46:	06b57263          	bgeu	a0,a1,ffffffffc0204baa <do_execve+0x4c4>
ffffffffc0204b4a:	000ab583          	ld	a1,0(s5)
ffffffffc0204b4e:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b52:	864e                	mv	a2,s3
ffffffffc0204b54:	96ae                	add	a3,a3,a1
ffffffffc0204b56:	9536                	add	a0,a0,a3
ffffffffc0204b58:	4581                	li	a1,0
            start += size;
ffffffffc0204b5a:	9b4e                	add	s6,s6,s3
ffffffffc0204b5c:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b5e:	51d000ef          	jal	ffffffffc020587a <memset>
        while (start < end)
ffffffffc0204b62:	d29b75e3          	bgeu	s6,s1,ffffffffc020488c <do_execve+0x1a6>
ffffffffc0204b66:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b68:	01893503          	ld	a0,24(s2)
ffffffffc0204b6c:	6622                	ld	a2,8(sp)
ffffffffc0204b6e:	85ee                	mv	a1,s11
ffffffffc0204b70:	92ffe0ef          	jal	ffffffffc020349e <pgdir_alloc_page>
ffffffffc0204b74:	842a                	mv	s0,a0
ffffffffc0204b76:	f15d                	bnez	a0,ffffffffc0204b1c <do_execve+0x436>
ffffffffc0204b78:	b5cd                	j	ffffffffc0204a5a <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204b7a:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b7c:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204b7e:	e43e                	sd	a5,8(sp)
ffffffffc0204b80:	b581                	j	ffffffffc02049c0 <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204b82:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204b84:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204b88:	e43e                	sd	a5,8(sp)
ffffffffc0204b8a:	bd1d                	j	ffffffffc02049c0 <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204b8c:	416d89b3          	sub	s3,s11,s6
ffffffffc0204b90:	bf19                	j	ffffffffc0204aa6 <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204b92:	54f5                	li	s1,-3
ffffffffc0204b94:	b3fd                	j	ffffffffc0204982 <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b96:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204b98:	84da                	mv	s1,s6
ffffffffc0204b9a:	bddd                	j	ffffffffc0204a90 <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204b9c:	54f1                	li	s1,-4
ffffffffc0204b9e:	b1ad                	j	ffffffffc0204808 <do_execve+0x122>
ffffffffc0204ba0:	6da6                	ld	s11,72(sp)
ffffffffc0204ba2:	bd75                	j	ffffffffc0204a5e <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204ba4:	6da6                	ld	s11,72(sp)
ffffffffc0204ba6:	54e1                	li	s1,-8
ffffffffc0204ba8:	bd5d                	j	ffffffffc0204a5e <do_execve+0x378>
ffffffffc0204baa:	00002617          	auipc	a2,0x2
ffffffffc0204bae:	ab660613          	addi	a2,a2,-1354 # ffffffffc0206660 <etext+0xdbc>
ffffffffc0204bb2:	07100593          	li	a1,113
ffffffffc0204bb6:	00002517          	auipc	a0,0x2
ffffffffc0204bba:	ad250513          	addi	a0,a0,-1326 # ffffffffc0206688 <etext+0xde4>
ffffffffc0204bbe:	88dfb0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0204bc2:	00002617          	auipc	a2,0x2
ffffffffc0204bc6:	a9e60613          	addi	a2,a2,-1378 # ffffffffc0206660 <etext+0xdbc>
ffffffffc0204bca:	07100593          	li	a1,113
ffffffffc0204bce:	00002517          	auipc	a0,0x2
ffffffffc0204bd2:	aba50513          	addi	a0,a0,-1350 # ffffffffc0206688 <etext+0xde4>
ffffffffc0204bd6:	f122                	sd	s0,160(sp)
ffffffffc0204bd8:	e152                	sd	s4,128(sp)
ffffffffc0204bda:	e4ee                	sd	s11,72(sp)
ffffffffc0204bdc:	86ffb0ef          	jal	ffffffffc020044a <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204be0:	00002617          	auipc	a2,0x2
ffffffffc0204be4:	b2860613          	addi	a2,a2,-1240 # ffffffffc0206708 <etext+0xe64>
ffffffffc0204be8:	2ef00593          	li	a1,751
ffffffffc0204bec:	00002517          	auipc	a0,0x2
ffffffffc0204bf0:	45c50513          	addi	a0,a0,1116 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204bf4:	e4ee                	sd	s11,72(sp)
ffffffffc0204bf6:	855fb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bfa:	00002697          	auipc	a3,0x2
ffffffffc0204bfe:	72e68693          	addi	a3,a3,1838 # ffffffffc0207328 <etext+0x1a84>
ffffffffc0204c02:	00001617          	auipc	a2,0x1
ffffffffc0204c06:	6ae60613          	addi	a2,a2,1710 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0204c0a:	2ea00593          	li	a1,746
ffffffffc0204c0e:	00002517          	auipc	a0,0x2
ffffffffc0204c12:	43a50513          	addi	a0,a0,1082 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204c16:	e4ee                	sd	s11,72(sp)
ffffffffc0204c18:	833fb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c1c:	00002697          	auipc	a3,0x2
ffffffffc0204c20:	6c468693          	addi	a3,a3,1732 # ffffffffc02072e0 <etext+0x1a3c>
ffffffffc0204c24:	00001617          	auipc	a2,0x1
ffffffffc0204c28:	68c60613          	addi	a2,a2,1676 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0204c2c:	2e900593          	li	a1,745
ffffffffc0204c30:	00002517          	auipc	a0,0x2
ffffffffc0204c34:	41850513          	addi	a0,a0,1048 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204c38:	e4ee                	sd	s11,72(sp)
ffffffffc0204c3a:	811fb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c3e:	00002697          	auipc	a3,0x2
ffffffffc0204c42:	65a68693          	addi	a3,a3,1626 # ffffffffc0207298 <etext+0x19f4>
ffffffffc0204c46:	00001617          	auipc	a2,0x1
ffffffffc0204c4a:	66a60613          	addi	a2,a2,1642 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0204c4e:	2e800593          	li	a1,744
ffffffffc0204c52:	00002517          	auipc	a0,0x2
ffffffffc0204c56:	3f650513          	addi	a0,a0,1014 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204c5a:	e4ee                	sd	s11,72(sp)
ffffffffc0204c5c:	feefb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204c60:	00002697          	auipc	a3,0x2
ffffffffc0204c64:	5f068693          	addi	a3,a3,1520 # ffffffffc0207250 <etext+0x19ac>
ffffffffc0204c68:	00001617          	auipc	a2,0x1
ffffffffc0204c6c:	64860613          	addi	a2,a2,1608 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0204c70:	2e700593          	li	a1,743
ffffffffc0204c74:	00002517          	auipc	a0,0x2
ffffffffc0204c78:	3d450513          	addi	a0,a0,980 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204c7c:	e4ee                	sd	s11,72(sp)
ffffffffc0204c7e:	fccfb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204c82 <user_main>:
{
ffffffffc0204c82:	1101                	addi	sp,sp,-32
ffffffffc0204c84:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c86:	000b1497          	auipc	s1,0xb1
ffffffffc0204c8a:	a1a48493          	addi	s1,s1,-1510 # ffffffffc02b56a0 <current>
ffffffffc0204c8e:	609c                	ld	a5,0(s1)
ffffffffc0204c90:	00002617          	auipc	a2,0x2
ffffffffc0204c94:	6e060613          	addi	a2,a2,1760 # ffffffffc0207370 <etext+0x1acc>
ffffffffc0204c98:	00002517          	auipc	a0,0x2
ffffffffc0204c9c:	6e850513          	addi	a0,a0,1768 # ffffffffc0207380 <etext+0x1adc>
ffffffffc0204ca0:	43cc                	lw	a1,4(a5)
{
ffffffffc0204ca2:	ec06                	sd	ra,24(sp)
ffffffffc0204ca4:	e822                	sd	s0,16(sp)
ffffffffc0204ca6:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204ca8:	cf0fb0ef          	jal	ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204cac:	00002517          	auipc	a0,0x2
ffffffffc0204cb0:	6c450513          	addi	a0,a0,1732 # ffffffffc0207370 <etext+0x1acc>
ffffffffc0204cb4:	313000ef          	jal	ffffffffc02057c6 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204cb8:	6098                	ld	a4,0(s1)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204cba:	6789                	lui	a5,0x2
ffffffffc0204cbc:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7048>
ffffffffc0204cc0:	6b00                	ld	s0,16(a4)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204cc2:	734c                	ld	a1,160(a4)
    size_t len = strlen(name);
ffffffffc0204cc4:	892a                	mv	s2,a0
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204cc6:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204cc8:	12000613          	li	a2,288
ffffffffc0204ccc:	8522                	mv	a0,s0
ffffffffc0204cce:	3bf000ef          	jal	ffffffffc020588c <memcpy>
    current->tf = new_tf;
ffffffffc0204cd2:	609c                	ld	a5,0(s1)
    ret = do_execve(name, len, binary, size);
ffffffffc0204cd4:	85ca                	mv	a1,s2
ffffffffc0204cd6:	3fe06697          	auipc	a3,0x3fe06
ffffffffc0204cda:	a4268693          	addi	a3,a3,-1470 # a718 <_binary_obj___user_priority_out_size>
    current->tf = new_tf;
ffffffffc0204cde:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204ce0:	00072617          	auipc	a2,0x72
ffffffffc0204ce4:	cb060613          	addi	a2,a2,-848 # ffffffffc0276990 <_binary_obj___user_priority_out_start>
ffffffffc0204ce8:	00002517          	auipc	a0,0x2
ffffffffc0204cec:	68850513          	addi	a0,a0,1672 # ffffffffc0207370 <etext+0x1acc>
ffffffffc0204cf0:	9f7ff0ef          	jal	ffffffffc02046e6 <do_execve>
    asm volatile(
ffffffffc0204cf4:	8122                	mv	sp,s0
ffffffffc0204cf6:	936fc06f          	j	ffffffffc0200e2c <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204cfa:	00002617          	auipc	a2,0x2
ffffffffc0204cfe:	6ae60613          	addi	a2,a2,1710 # ffffffffc02073a8 <etext+0x1b04>
ffffffffc0204d02:	3d200593          	li	a1,978
ffffffffc0204d06:	00002517          	auipc	a0,0x2
ffffffffc0204d0a:	34250513          	addi	a0,a0,834 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204d0e:	f3cfb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204d12 <do_yield>:
    current->need_resched = 1;
ffffffffc0204d12:	000b1797          	auipc	a5,0xb1
ffffffffc0204d16:	98e7b783          	ld	a5,-1650(a5) # ffffffffc02b56a0 <current>
ffffffffc0204d1a:	4705                	li	a4,1
}
ffffffffc0204d1c:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204d1e:	ef98                	sd	a4,24(a5)
}
ffffffffc0204d20:	8082                	ret

ffffffffc0204d22 <do_wait>:
    if (code_store != NULL)
ffffffffc0204d22:	c59d                	beqz	a1,ffffffffc0204d50 <do_wait+0x2e>
{
ffffffffc0204d24:	1101                	addi	sp,sp,-32
ffffffffc0204d26:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204d28:	000b1517          	auipc	a0,0xb1
ffffffffc0204d2c:	97853503          	ld	a0,-1672(a0) # ffffffffc02b56a0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d30:	4685                	li	a3,1
ffffffffc0204d32:	4611                	li	a2,4
ffffffffc0204d34:	7508                	ld	a0,40(a0)
{
ffffffffc0204d36:	ec06                	sd	ra,24(sp)
ffffffffc0204d38:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d3a:	ed3fe0ef          	jal	ffffffffc0203c0c <user_mem_check>
ffffffffc0204d3e:	6702                	ld	a4,0(sp)
ffffffffc0204d40:	67a2                	ld	a5,8(sp)
ffffffffc0204d42:	c909                	beqz	a0,ffffffffc0204d54 <do_wait+0x32>
}
ffffffffc0204d44:	60e2                	ld	ra,24(sp)
ffffffffc0204d46:	85be                	mv	a1,a5
ffffffffc0204d48:	853a                	mv	a0,a4
ffffffffc0204d4a:	6105                	addi	sp,sp,32
ffffffffc0204d4c:	e94ff06f          	j	ffffffffc02043e0 <do_wait.part.0>
ffffffffc0204d50:	e90ff06f          	j	ffffffffc02043e0 <do_wait.part.0>
ffffffffc0204d54:	60e2                	ld	ra,24(sp)
ffffffffc0204d56:	5575                	li	a0,-3
ffffffffc0204d58:	6105                	addi	sp,sp,32
ffffffffc0204d5a:	8082                	ret

ffffffffc0204d5c <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d5c:	6789                	lui	a5,0x2
ffffffffc0204d5e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d62:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f2a>
ffffffffc0204d64:	06e7e463          	bltu	a5,a4,ffffffffc0204dcc <do_kill+0x70>
{
ffffffffc0204d68:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d6a:	45a9                	li	a1,10
{
ffffffffc0204d6c:	ec06                	sd	ra,24(sp)
ffffffffc0204d6e:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d70:	674000ef          	jal	ffffffffc02053e4 <hash32>
ffffffffc0204d74:	02051793          	slli	a5,a0,0x20
ffffffffc0204d78:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204d7c:	000ad797          	auipc	a5,0xad
ffffffffc0204d80:	88478793          	addi	a5,a5,-1916 # ffffffffc02b1600 <hash_list>
ffffffffc0204d84:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204d86:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d88:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204d8a:	a029                	j	ffffffffc0204d94 <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204d8c:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204d90:	00c70963          	beq	a4,a2,ffffffffc0204da2 <do_kill+0x46>
ffffffffc0204d94:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204d96:	fea69be3          	bne	a3,a0,ffffffffc0204d8c <do_kill+0x30>
}
ffffffffc0204d9a:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204d9c:	5575                	li	a0,-3
}
ffffffffc0204d9e:	6105                	addi	sp,sp,32
ffffffffc0204da0:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204da2:	fd852703          	lw	a4,-40(a0)
ffffffffc0204da6:	00177693          	andi	a3,a4,1
ffffffffc0204daa:	e29d                	bnez	a3,ffffffffc0204dd0 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204dac:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204dae:	00176713          	ori	a4,a4,1
ffffffffc0204db2:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204db6:	0006c663          	bltz	a3,ffffffffc0204dc2 <do_kill+0x66>
            return 0;
ffffffffc0204dba:	4501                	li	a0,0
}
ffffffffc0204dbc:	60e2                	ld	ra,24(sp)
ffffffffc0204dbe:	6105                	addi	sp,sp,32
ffffffffc0204dc0:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204dc2:	f2850513          	addi	a0,a0,-216
ffffffffc0204dc6:	374000ef          	jal	ffffffffc020513a <wakeup_proc>
ffffffffc0204dca:	bfc5                	j	ffffffffc0204dba <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204dcc:	5575                	li	a0,-3
}
ffffffffc0204dce:	8082                	ret
        return -E_KILLED;
ffffffffc0204dd0:	555d                	li	a0,-9
ffffffffc0204dd2:	b7ed                	j	ffffffffc0204dbc <do_kill+0x60>

ffffffffc0204dd4 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204dd4:	1101                	addi	sp,sp,-32
ffffffffc0204dd6:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204dd8:	000b1797          	auipc	a5,0xb1
ffffffffc0204ddc:	82878793          	addi	a5,a5,-2008 # ffffffffc02b5600 <proc_list>
ffffffffc0204de0:	ec06                	sd	ra,24(sp)
ffffffffc0204de2:	e822                	sd	s0,16(sp)
ffffffffc0204de4:	e04a                	sd	s2,0(sp)
ffffffffc0204de6:	000ad497          	auipc	s1,0xad
ffffffffc0204dea:	81a48493          	addi	s1,s1,-2022 # ffffffffc02b1600 <hash_list>
ffffffffc0204dee:	e79c                	sd	a5,8(a5)
ffffffffc0204df0:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204df2:	000b1717          	auipc	a4,0xb1
ffffffffc0204df6:	80e70713          	addi	a4,a4,-2034 # ffffffffc02b5600 <proc_list>
ffffffffc0204dfa:	87a6                	mv	a5,s1
ffffffffc0204dfc:	e79c                	sd	a5,8(a5)
ffffffffc0204dfe:	e39c                	sd	a5,0(a5)
ffffffffc0204e00:	07c1                	addi	a5,a5,16
ffffffffc0204e02:	fee79de3          	bne	a5,a4,ffffffffc0204dfc <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204e06:	eb3fe0ef          	jal	ffffffffc0203cb8 <alloc_proc>
ffffffffc0204e0a:	000b1917          	auipc	s2,0xb1
ffffffffc0204e0e:	8a690913          	addi	s2,s2,-1882 # ffffffffc02b56b0 <idleproc>
ffffffffc0204e12:	00a93023          	sd	a0,0(s2)
ffffffffc0204e16:	10050363          	beqz	a0,ffffffffc0204f1c <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204e1a:	4789                	li	a5,2
ffffffffc0204e1c:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e1e:	00004797          	auipc	a5,0x4
ffffffffc0204e22:	1e278793          	addi	a5,a5,482 # ffffffffc0209000 <bootstack>
ffffffffc0204e26:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e28:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0204e2c:	4785                	li	a5,1
ffffffffc0204e2e:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e30:	4641                	li	a2,16
ffffffffc0204e32:	8522                	mv	a0,s0
ffffffffc0204e34:	4581                	li	a1,0
ffffffffc0204e36:	245000ef          	jal	ffffffffc020587a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e3a:	8522                	mv	a0,s0
ffffffffc0204e3c:	463d                	li	a2,15
ffffffffc0204e3e:	00002597          	auipc	a1,0x2
ffffffffc0204e42:	5a258593          	addi	a1,a1,1442 # ffffffffc02073e0 <etext+0x1b3c>
ffffffffc0204e46:	247000ef          	jal	ffffffffc020588c <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204e4a:	000b1797          	auipc	a5,0xb1
ffffffffc0204e4e:	84e7a783          	lw	a5,-1970(a5) # ffffffffc02b5698 <nr_process>

    current = idleproc;
ffffffffc0204e52:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e56:	4601                	li	a2,0
    nr_process++;
ffffffffc0204e58:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e5a:	4581                	li	a1,0
ffffffffc0204e5c:	fffff517          	auipc	a0,0xfffff
ffffffffc0204e60:	76650513          	addi	a0,a0,1894 # ffffffffc02045c2 <init_main>
    current = idleproc;
ffffffffc0204e64:	000b1697          	auipc	a3,0xb1
ffffffffc0204e68:	82e6be23          	sd	a4,-1988(a3) # ffffffffc02b56a0 <current>
    nr_process++;
ffffffffc0204e6c:	000b1717          	auipc	a4,0xb1
ffffffffc0204e70:	82f72623          	sw	a5,-2004(a4) # ffffffffc02b5698 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e74:	bd8ff0ef          	jal	ffffffffc020424c <kernel_thread>
ffffffffc0204e78:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204e7a:	08a05563          	blez	a0,ffffffffc0204f04 <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e7e:	6789                	lui	a5,0x2
ffffffffc0204e80:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f2a>
ffffffffc0204e82:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e86:	02e7e463          	bltu	a5,a4,ffffffffc0204eae <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e8a:	45a9                	li	a1,10
ffffffffc0204e8c:	558000ef          	jal	ffffffffc02053e4 <hash32>
ffffffffc0204e90:	02051713          	slli	a4,a0,0x20
ffffffffc0204e94:	01c75793          	srli	a5,a4,0x1c
ffffffffc0204e98:	00f486b3          	add	a3,s1,a5
ffffffffc0204e9c:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204e9e:	a029                	j	ffffffffc0204ea8 <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc0204ea0:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204ea4:	04870d63          	beq	a4,s0,ffffffffc0204efe <proc_init+0x12a>
    return listelm->next;
ffffffffc0204ea8:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204eaa:	fef69be3          	bne	a3,a5,ffffffffc0204ea0 <proc_init+0xcc>
    return NULL;
ffffffffc0204eae:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204eb0:	0b478413          	addi	s0,a5,180
ffffffffc0204eb4:	4641                	li	a2,16
ffffffffc0204eb6:	4581                	li	a1,0
ffffffffc0204eb8:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204eba:	000b0717          	auipc	a4,0xb0
ffffffffc0204ebe:	7ef73723          	sd	a5,2030(a4) # ffffffffc02b56a8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ec2:	1b9000ef          	jal	ffffffffc020587a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ec6:	8522                	mv	a0,s0
ffffffffc0204ec8:	463d                	li	a2,15
ffffffffc0204eca:	00002597          	auipc	a1,0x2
ffffffffc0204ece:	53e58593          	addi	a1,a1,1342 # ffffffffc0207408 <etext+0x1b64>
ffffffffc0204ed2:	1bb000ef          	jal	ffffffffc020588c <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204ed6:	00093783          	ld	a5,0(s2)
ffffffffc0204eda:	cfad                	beqz	a5,ffffffffc0204f54 <proc_init+0x180>
ffffffffc0204edc:	43dc                	lw	a5,4(a5)
ffffffffc0204ede:	ebbd                	bnez	a5,ffffffffc0204f54 <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204ee0:	000b0797          	auipc	a5,0xb0
ffffffffc0204ee4:	7c87b783          	ld	a5,1992(a5) # ffffffffc02b56a8 <initproc>
ffffffffc0204ee8:	c7b1                	beqz	a5,ffffffffc0204f34 <proc_init+0x160>
ffffffffc0204eea:	43d8                	lw	a4,4(a5)
ffffffffc0204eec:	4785                	li	a5,1
ffffffffc0204eee:	04f71363          	bne	a4,a5,ffffffffc0204f34 <proc_init+0x160>
}
ffffffffc0204ef2:	60e2                	ld	ra,24(sp)
ffffffffc0204ef4:	6442                	ld	s0,16(sp)
ffffffffc0204ef6:	64a2                	ld	s1,8(sp)
ffffffffc0204ef8:	6902                	ld	s2,0(sp)
ffffffffc0204efa:	6105                	addi	sp,sp,32
ffffffffc0204efc:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204efe:	f2878793          	addi	a5,a5,-216
ffffffffc0204f02:	b77d                	j	ffffffffc0204eb0 <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc0204f04:	00002617          	auipc	a2,0x2
ffffffffc0204f08:	4e460613          	addi	a2,a2,1252 # ffffffffc02073e8 <etext+0x1b44>
ffffffffc0204f0c:	40e00593          	li	a1,1038
ffffffffc0204f10:	00002517          	auipc	a0,0x2
ffffffffc0204f14:	13850513          	addi	a0,a0,312 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204f18:	d32fb0ef          	jal	ffffffffc020044a <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204f1c:	00002617          	auipc	a2,0x2
ffffffffc0204f20:	4ac60613          	addi	a2,a2,1196 # ffffffffc02073c8 <etext+0x1b24>
ffffffffc0204f24:	3ff00593          	li	a1,1023
ffffffffc0204f28:	00002517          	auipc	a0,0x2
ffffffffc0204f2c:	12050513          	addi	a0,a0,288 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204f30:	d1afb0ef          	jal	ffffffffc020044a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f34:	00002697          	auipc	a3,0x2
ffffffffc0204f38:	50468693          	addi	a3,a3,1284 # ffffffffc0207438 <etext+0x1b94>
ffffffffc0204f3c:	00001617          	auipc	a2,0x1
ffffffffc0204f40:	37460613          	addi	a2,a2,884 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0204f44:	41500593          	li	a1,1045
ffffffffc0204f48:	00002517          	auipc	a0,0x2
ffffffffc0204f4c:	10050513          	addi	a0,a0,256 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204f50:	cfafb0ef          	jal	ffffffffc020044a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f54:	00002697          	auipc	a3,0x2
ffffffffc0204f58:	4bc68693          	addi	a3,a3,1212 # ffffffffc0207410 <etext+0x1b6c>
ffffffffc0204f5c:	00001617          	auipc	a2,0x1
ffffffffc0204f60:	35460613          	addi	a2,a2,852 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0204f64:	41400593          	li	a1,1044
ffffffffc0204f68:	00002517          	auipc	a0,0x2
ffffffffc0204f6c:	0e050513          	addi	a0,a0,224 # ffffffffc0207048 <etext+0x17a4>
ffffffffc0204f70:	cdafb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204f74 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204f74:	1141                	addi	sp,sp,-16
ffffffffc0204f76:	e022                	sd	s0,0(sp)
ffffffffc0204f78:	e406                	sd	ra,8(sp)
ffffffffc0204f7a:	000b0417          	auipc	s0,0xb0
ffffffffc0204f7e:	72640413          	addi	s0,s0,1830 # ffffffffc02b56a0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204f82:	6018                	ld	a4,0(s0)
ffffffffc0204f84:	6f1c                	ld	a5,24(a4)
ffffffffc0204f86:	dffd                	beqz	a5,ffffffffc0204f84 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204f88:	2aa000ef          	jal	ffffffffc0205232 <schedule>
ffffffffc0204f8c:	bfdd                	j	ffffffffc0204f82 <cpu_idle+0xe>

ffffffffc0204f8e <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0204f8e:	1101                	addi	sp,sp,-32
ffffffffc0204f90:	85aa                	mv	a1,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0204f92:	e42a                	sd	a0,8(sp)
ffffffffc0204f94:	00002517          	auipc	a0,0x2
ffffffffc0204f98:	4cc50513          	addi	a0,a0,1228 # ffffffffc0207460 <etext+0x1bbc>
{
ffffffffc0204f9c:	ec06                	sd	ra,24(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204f9e:	9fafb0ef          	jal	ffffffffc0200198 <cprintf>
    if (priority == 0)
ffffffffc0204fa2:	65a2                	ld	a1,8(sp)
        current->lab6_priority = 1;
ffffffffc0204fa4:	000b0717          	auipc	a4,0xb0
ffffffffc0204fa8:	6fc73703          	ld	a4,1788(a4) # ffffffffc02b56a0 <current>
    if (priority == 0)
ffffffffc0204fac:	4785                	li	a5,1
ffffffffc0204fae:	c191                	beqz	a1,ffffffffc0204fb2 <lab6_set_priority+0x24>
ffffffffc0204fb0:	87ae                	mv	a5,a1
    else
        current->lab6_priority = priority;
}
ffffffffc0204fb2:	60e2                	ld	ra,24(sp)
        current->lab6_priority = 1;
ffffffffc0204fb4:	14f72223          	sw	a5,324(a4)
}
ffffffffc0204fb8:	6105                	addi	sp,sp,32
ffffffffc0204fba:	8082                	ret

ffffffffc0204fbc <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204fbc:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204fc0:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204fc4:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204fc6:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204fc8:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204fcc:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204fd0:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204fd4:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204fd8:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204fdc:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204fe0:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204fe4:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204fe8:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204fec:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204ff0:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204ff4:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204ff8:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204ffa:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204ffc:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205000:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205004:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205008:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020500c:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205010:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205014:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205018:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020501c:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205020:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205024:	8082                	ret

ffffffffc0205026 <RR_init>:
    elm->prev = elm->next = elm;
ffffffffc0205026:	e508                	sd	a0,8(a0)
ffffffffc0205028:	e108                	sd	a0,0(a0)
static void
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_init(&(rq->run_list)); // 把 rq->run_list 初始化为空双向循环链表头
    rq->proc_num = 0; // 把运行队列中的进程计数器置 0，表示当前队列无进程
ffffffffc020502a:	00052823          	sw	zero,16(a0)
}
ffffffffc020502e:	8082                	ret

ffffffffc0205030 <RR_dequeue>:
    return list->next == list;
ffffffffc0205030:	1185b703          	ld	a4,280(a1)
 */
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    if(!list_empty(&(proc->run_link)) && proc->rq == rq){ // proc->run_link 非空并且 proc 所属的 rq 是传入的 rq
ffffffffc0205034:	11058793          	addi	a5,a1,272
ffffffffc0205038:	00e78663          	beq	a5,a4,ffffffffc0205044 <RR_dequeue+0x14>
ffffffffc020503c:	1085b683          	ld	a3,264(a1)
ffffffffc0205040:	00a68363          	beq	a3,a0,ffffffffc0205046 <RR_dequeue+0x16>
        list_del_init(&(proc->run_link)); // 从链表中删除 proc->run_link，并把该结点重置为链表初始状态
        rq->proc_num --;
    }
}
ffffffffc0205044:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0205046:	1105b503          	ld	a0,272(a1)
        rq->proc_num --;
ffffffffc020504a:	4a90                	lw	a2,16(a3)
    prev->next = next;
ffffffffc020504c:	e518                	sd	a4,8(a0)
    next->prev = prev;
ffffffffc020504e:	e308                	sd	a0,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0205050:	10f5bc23          	sd	a5,280(a1)
ffffffffc0205054:	10f5b823          	sd	a5,272(a1)
ffffffffc0205058:	367d                	addiw	a2,a2,-1
ffffffffc020505a:	ca90                	sw	a2,16(a3)
}
ffffffffc020505c:	8082                	ret

ffffffffc020505e <RR_pick_next>:
    return listelm->next;
ffffffffc020505e:	651c                	ld	a5,8(a0)
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_entry_t *le = list_next(&(rq->run_list)); // 获取运行队列中第一个进程的链表结点
    if (le != &(rq->run_list)) { // 不能是头部本身
ffffffffc0205060:	00f50563          	beq	a0,a5,ffffffffc020506a <RR_pick_next+0xc>
        return le2proc(le, run_link); // 用 le2proc 宏把链表结点转换为对应的 proc_struct 指针并返回
ffffffffc0205064:	ef078513          	addi	a0,a5,-272
ffffffffc0205068:	8082                	ret
    }
    return NULL;
ffffffffc020506a:	4501                	li	a0,0
}
ffffffffc020506c:	8082                	ret

ffffffffc020506e <RR_proc_tick>:
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{ // 此函数在当前进程的时钟滴答事件触发时被调用，应减少 proc->time_slice 并在耗尽时将进程的需要重新调度标志置为 1
    // LAB6: YOUR CODE
    if (proc->time_slice > 0) {
ffffffffc020506e:	1205a783          	lw	a5,288(a1)
ffffffffc0205072:	00f05563          	blez	a5,ffffffffc020507c <RR_proc_tick+0xe>
        proc->time_slice --;
ffffffffc0205076:	37fd                	addiw	a5,a5,-1
ffffffffc0205078:	12f5a023          	sw	a5,288(a1)
    }
    if (proc->time_slice == 0) {
ffffffffc020507c:	e399                	bnez	a5,ffffffffc0205082 <RR_proc_tick+0x14>
        proc->need_resched = 1;
ffffffffc020507e:	4785                	li	a5,1
ffffffffc0205080:	ed9c                	sd	a5,24(a1)
    }
}
ffffffffc0205082:	8082                	ret

ffffffffc0205084 <RR_enqueue>:
    if(list_empty(&(proc->run_link))){ // 当 proc 的 run_link 链表结点为空时
ffffffffc0205084:	1185b703          	ld	a4,280(a1)
ffffffffc0205088:	11058793          	addi	a5,a1,272
ffffffffc020508c:	00e78363          	beq	a5,a4,ffffffffc0205092 <RR_enqueue+0xe>
}
ffffffffc0205090:	8082                	ret
    __list_add(elm, listelm->prev, listelm);
ffffffffc0205092:	6118                	ld	a4,0(a0)
        if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) { // 检查 proc 当前 time_slice 是否未初始化（0）或超过队列允许的最大时间片
ffffffffc0205094:	1205a683          	lw	a3,288(a1)
    prev->next = next->prev = elm;
ffffffffc0205098:	e11c                	sd	a5,0(a0)
ffffffffc020509a:	e71c                	sd	a5,8(a4)
    elm->prev = prev;
ffffffffc020509c:	10e5b823          	sd	a4,272(a1)
    elm->next = next;
ffffffffc02050a0:	10a5bc23          	sd	a0,280(a1)
ffffffffc02050a4:	495c                	lw	a5,20(a0)
ffffffffc02050a6:	ea89                	bnez	a3,ffffffffc02050b8 <RR_enqueue+0x34>
            proc->time_slice = rq->max_time_slice; // 分配时间片
ffffffffc02050a8:	12f5a023          	sw	a5,288(a1)
        rq->proc_num ++;
ffffffffc02050ac:	491c                	lw	a5,16(a0)
        proc->rq = rq; // 把 proc 的 rq 指针设置为当前运行队列
ffffffffc02050ae:	10a5b423          	sd	a0,264(a1)
        rq->proc_num ++;
ffffffffc02050b2:	2785                	addiw	a5,a5,1
ffffffffc02050b4:	c91c                	sw	a5,16(a0)
}
ffffffffc02050b6:	8082                	ret
        if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) { // 检查 proc 当前 time_slice 是否未初始化（0）或超过队列允许的最大时间片
ffffffffc02050b8:	fed7dae3          	bge	a5,a3,ffffffffc02050ac <RR_enqueue+0x28>
ffffffffc02050bc:	b7f5                	j	ffffffffc02050a8 <RR_enqueue+0x24>

ffffffffc02050be <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc02050be:	000b0797          	auipc	a5,0xb0
ffffffffc02050c2:	5f27b783          	ld	a5,1522(a5) # ffffffffc02b56b0 <idleproc>
{
ffffffffc02050c6:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc02050c8:	00a78c63          	beq	a5,a0,ffffffffc02050e0 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc02050cc:	000b0797          	auipc	a5,0xb0
ffffffffc02050d0:	5f47b783          	ld	a5,1524(a5) # ffffffffc02b56c0 <sched_class>
ffffffffc02050d4:	000b0517          	auipc	a0,0xb0
ffffffffc02050d8:	5e453503          	ld	a0,1508(a0) # ffffffffc02b56b8 <rq>
ffffffffc02050dc:	779c                	ld	a5,40(a5)
ffffffffc02050de:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc02050e0:	4705                	li	a4,1
ffffffffc02050e2:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc02050e4:	8082                	ret

ffffffffc02050e6 <sched_init>:

void sched_init(void)
{
    list_init(&timer_list);

    sched_class = &default_sched_class;
ffffffffc02050e6:	000ac797          	auipc	a5,0xac
ffffffffc02050ea:	0c278793          	addi	a5,a5,194 # ffffffffc02b11a8 <default_sched_class>
{
ffffffffc02050ee:	1141                	addi	sp,sp,-16

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc02050f0:	6794                	ld	a3,8(a5)
    sched_class = &default_sched_class;
ffffffffc02050f2:	000b0717          	auipc	a4,0xb0
ffffffffc02050f6:	5cf73723          	sd	a5,1486(a4) # ffffffffc02b56c0 <sched_class>
{
ffffffffc02050fa:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc02050fc:	000b0797          	auipc	a5,0xb0
ffffffffc0205100:	53478793          	addi	a5,a5,1332 # ffffffffc02b5630 <timer_list>
    rq = &__rq;
ffffffffc0205104:	000b0717          	auipc	a4,0xb0
ffffffffc0205108:	50c70713          	addi	a4,a4,1292 # ffffffffc02b5610 <__rq>
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc020510c:	4615                	li	a2,5
ffffffffc020510e:	e79c                	sd	a5,8(a5)
ffffffffc0205110:	e39c                	sd	a5,0(a5)
    sched_class->init(rq);
ffffffffc0205112:	853a                	mv	a0,a4
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc0205114:	cb50                	sw	a2,20(a4)
    rq = &__rq;
ffffffffc0205116:	000b0797          	auipc	a5,0xb0
ffffffffc020511a:	5ae7b123          	sd	a4,1442(a5) # ffffffffc02b56b8 <rq>
    sched_class->init(rq);
ffffffffc020511e:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205120:	000b0797          	auipc	a5,0xb0
ffffffffc0205124:	5a07b783          	ld	a5,1440(a5) # ffffffffc02b56c0 <sched_class>
}
ffffffffc0205128:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020512a:	00002517          	auipc	a0,0x2
ffffffffc020512e:	35e50513          	addi	a0,a0,862 # ffffffffc0207488 <etext+0x1be4>
ffffffffc0205132:	638c                	ld	a1,0(a5)
}
ffffffffc0205134:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205136:	862fb06f          	j	ffffffffc0200198 <cprintf>

ffffffffc020513a <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020513a:	4118                	lw	a4,0(a0)
{
ffffffffc020513c:	1101                	addi	sp,sp,-32
ffffffffc020513e:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205140:	478d                	li	a5,3
ffffffffc0205142:	0cf70863          	beq	a4,a5,ffffffffc0205212 <wakeup_proc+0xd8>
ffffffffc0205146:	85aa                	mv	a1,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205148:	100027f3          	csrr	a5,sstatus
ffffffffc020514c:	8b89                	andi	a5,a5,2
ffffffffc020514e:	e3b1                	bnez	a5,ffffffffc0205192 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205150:	4789                	li	a5,2
ffffffffc0205152:	08f70563          	beq	a4,a5,ffffffffc02051dc <wakeup_proc+0xa2>
        {
            proc->state = PROC_RUNNABLE;
            proc->wait_state = 0;
            if (proc != current)
ffffffffc0205156:	000b0717          	auipc	a4,0xb0
ffffffffc020515a:	54a73703          	ld	a4,1354(a4) # ffffffffc02b56a0 <current>
            proc->wait_state = 0;
ffffffffc020515e:	0e052623          	sw	zero,236(a0)
            proc->state = PROC_RUNNABLE;
ffffffffc0205162:	c11c                	sw	a5,0(a0)
            if (proc != current)
ffffffffc0205164:	02e50463          	beq	a0,a4,ffffffffc020518c <wakeup_proc+0x52>
    if (proc != idleproc)
ffffffffc0205168:	000b0797          	auipc	a5,0xb0
ffffffffc020516c:	5487b783          	ld	a5,1352(a5) # ffffffffc02b56b0 <idleproc>
ffffffffc0205170:	00f50e63          	beq	a0,a5,ffffffffc020518c <wakeup_proc+0x52>
        sched_class->enqueue(rq, proc);
ffffffffc0205174:	000b0797          	auipc	a5,0xb0
ffffffffc0205178:	54c7b783          	ld	a5,1356(a5) # ffffffffc02b56c0 <sched_class>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020517c:	60e2                	ld	ra,24(sp)
        sched_class->enqueue(rq, proc);
ffffffffc020517e:	000b0517          	auipc	a0,0xb0
ffffffffc0205182:	53a53503          	ld	a0,1338(a0) # ffffffffc02b56b8 <rq>
ffffffffc0205186:	6b9c                	ld	a5,16(a5)
}
ffffffffc0205188:	6105                	addi	sp,sp,32
        sched_class->enqueue(rq, proc);
ffffffffc020518a:	8782                	jr	a5
}
ffffffffc020518c:	60e2                	ld	ra,24(sp)
ffffffffc020518e:	6105                	addi	sp,sp,32
ffffffffc0205190:	8082                	ret
        intr_disable();
ffffffffc0205192:	e42a                	sd	a0,8(sp)
ffffffffc0205194:	f6afb0ef          	jal	ffffffffc02008fe <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205198:	65a2                	ld	a1,8(sp)
ffffffffc020519a:	4789                	li	a5,2
ffffffffc020519c:	4198                	lw	a4,0(a1)
ffffffffc020519e:	04f70d63          	beq	a4,a5,ffffffffc02051f8 <wakeup_proc+0xbe>
            if (proc != current)
ffffffffc02051a2:	000b0717          	auipc	a4,0xb0
ffffffffc02051a6:	4fe73703          	ld	a4,1278(a4) # ffffffffc02b56a0 <current>
            proc->wait_state = 0;
ffffffffc02051aa:	0e05a623          	sw	zero,236(a1)
            proc->state = PROC_RUNNABLE;
ffffffffc02051ae:	c19c                	sw	a5,0(a1)
            if (proc != current)
ffffffffc02051b0:	02e58263          	beq	a1,a4,ffffffffc02051d4 <wakeup_proc+0x9a>
    if (proc != idleproc)
ffffffffc02051b4:	000b0797          	auipc	a5,0xb0
ffffffffc02051b8:	4fc7b783          	ld	a5,1276(a5) # ffffffffc02b56b0 <idleproc>
ffffffffc02051bc:	00f58c63          	beq	a1,a5,ffffffffc02051d4 <wakeup_proc+0x9a>
        sched_class->enqueue(rq, proc);
ffffffffc02051c0:	000b0797          	auipc	a5,0xb0
ffffffffc02051c4:	5007b783          	ld	a5,1280(a5) # ffffffffc02b56c0 <sched_class>
ffffffffc02051c8:	000b0517          	auipc	a0,0xb0
ffffffffc02051cc:	4f053503          	ld	a0,1264(a0) # ffffffffc02b56b8 <rq>
ffffffffc02051d0:	6b9c                	ld	a5,16(a5)
ffffffffc02051d2:	9782                	jalr	a5
}
ffffffffc02051d4:	60e2                	ld	ra,24(sp)
ffffffffc02051d6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051d8:	f20fb06f          	j	ffffffffc02008f8 <intr_enable>
ffffffffc02051dc:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc02051de:	00002617          	auipc	a2,0x2
ffffffffc02051e2:	2fa60613          	addi	a2,a2,762 # ffffffffc02074d8 <etext+0x1c34>
ffffffffc02051e6:	05100593          	li	a1,81
ffffffffc02051ea:	00002517          	auipc	a0,0x2
ffffffffc02051ee:	2d650513          	addi	a0,a0,726 # ffffffffc02074c0 <etext+0x1c1c>
}
ffffffffc02051f2:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc02051f4:	ac0fb06f          	j	ffffffffc02004b4 <__warn>
ffffffffc02051f8:	00002617          	auipc	a2,0x2
ffffffffc02051fc:	2e060613          	addi	a2,a2,736 # ffffffffc02074d8 <etext+0x1c34>
ffffffffc0205200:	05100593          	li	a1,81
ffffffffc0205204:	00002517          	auipc	a0,0x2
ffffffffc0205208:	2bc50513          	addi	a0,a0,700 # ffffffffc02074c0 <etext+0x1c1c>
ffffffffc020520c:	aa8fb0ef          	jal	ffffffffc02004b4 <__warn>
    if (flag)
ffffffffc0205210:	b7d1                	j	ffffffffc02051d4 <wakeup_proc+0x9a>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205212:	00002697          	auipc	a3,0x2
ffffffffc0205216:	28e68693          	addi	a3,a3,654 # ffffffffc02074a0 <etext+0x1bfc>
ffffffffc020521a:	00001617          	auipc	a2,0x1
ffffffffc020521e:	09660613          	addi	a2,a2,150 # ffffffffc02062b0 <etext+0xa0c>
ffffffffc0205222:	04200593          	li	a1,66
ffffffffc0205226:	00002517          	auipc	a0,0x2
ffffffffc020522a:	29a50513          	addi	a0,a0,666 # ffffffffc02074c0 <etext+0x1c1c>
ffffffffc020522e:	a1cfb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0205232 <schedule>:

void schedule(void)
{
ffffffffc0205232:	7139                	addi	sp,sp,-64
ffffffffc0205234:	fc06                	sd	ra,56(sp)
ffffffffc0205236:	f822                	sd	s0,48(sp)
ffffffffc0205238:	f426                	sd	s1,40(sp)
ffffffffc020523a:	f04a                	sd	s2,32(sp)
ffffffffc020523c:	ec4e                	sd	s3,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020523e:	100027f3          	csrr	a5,sstatus
ffffffffc0205242:	8b89                	andi	a5,a5,2
ffffffffc0205244:	4981                	li	s3,0
ffffffffc0205246:	efc9                	bnez	a5,ffffffffc02052e0 <schedule+0xae>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205248:	000b0417          	auipc	s0,0xb0
ffffffffc020524c:	45840413          	addi	s0,s0,1112 # ffffffffc02b56a0 <current>
ffffffffc0205250:	600c                	ld	a1,0(s0)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205252:	4789                	li	a5,2
ffffffffc0205254:	000b0497          	auipc	s1,0xb0
ffffffffc0205258:	46448493          	addi	s1,s1,1124 # ffffffffc02b56b8 <rq>
ffffffffc020525c:	4198                	lw	a4,0(a1)
        current->need_resched = 0;
ffffffffc020525e:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205262:	000b0917          	auipc	s2,0xb0
ffffffffc0205266:	45e90913          	addi	s2,s2,1118 # ffffffffc02b56c0 <sched_class>
ffffffffc020526a:	04f70f63          	beq	a4,a5,ffffffffc02052c8 <schedule+0x96>
    return sched_class->pick_next(rq);
ffffffffc020526e:	00093783          	ld	a5,0(s2)
ffffffffc0205272:	6088                	ld	a0,0(s1)
ffffffffc0205274:	739c                	ld	a5,32(a5)
ffffffffc0205276:	9782                	jalr	a5
ffffffffc0205278:	85aa                	mv	a1,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc020527a:	c131                	beqz	a0,ffffffffc02052be <schedule+0x8c>
    sched_class->dequeue(rq, proc);
ffffffffc020527c:	00093783          	ld	a5,0(s2)
ffffffffc0205280:	6088                	ld	a0,0(s1)
ffffffffc0205282:	e42e                	sd	a1,8(sp)
ffffffffc0205284:	6f9c                	ld	a5,24(a5)
ffffffffc0205286:	9782                	jalr	a5
ffffffffc0205288:	65a2                	ld	a1,8(sp)
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020528a:	459c                	lw	a5,8(a1)
        if (next != current)
ffffffffc020528c:	6018                	ld	a4,0(s0)
        next->runs++;
ffffffffc020528e:	2785                	addiw	a5,a5,1
ffffffffc0205290:	c59c                	sw	a5,8(a1)
        if (next != current)
ffffffffc0205292:	00b70563          	beq	a4,a1,ffffffffc020529c <schedule+0x6a>
        {
            proc_run(next);
ffffffffc0205296:	852e                	mv	a0,a1
ffffffffc0205298:	b3ffe0ef          	jal	ffffffffc0203dd6 <proc_run>
    if (flag)
ffffffffc020529c:	00099963          	bnez	s3,ffffffffc02052ae <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02052a0:	70e2                	ld	ra,56(sp)
ffffffffc02052a2:	7442                	ld	s0,48(sp)
ffffffffc02052a4:	74a2                	ld	s1,40(sp)
ffffffffc02052a6:	7902                	ld	s2,32(sp)
ffffffffc02052a8:	69e2                	ld	s3,24(sp)
ffffffffc02052aa:	6121                	addi	sp,sp,64
ffffffffc02052ac:	8082                	ret
ffffffffc02052ae:	7442                	ld	s0,48(sp)
ffffffffc02052b0:	70e2                	ld	ra,56(sp)
ffffffffc02052b2:	74a2                	ld	s1,40(sp)
ffffffffc02052b4:	7902                	ld	s2,32(sp)
ffffffffc02052b6:	69e2                	ld	s3,24(sp)
ffffffffc02052b8:	6121                	addi	sp,sp,64
        intr_enable();
ffffffffc02052ba:	e3efb06f          	j	ffffffffc02008f8 <intr_enable>
            next = idleproc;
ffffffffc02052be:	000b0597          	auipc	a1,0xb0
ffffffffc02052c2:	3f25b583          	ld	a1,1010(a1) # ffffffffc02b56b0 <idleproc>
ffffffffc02052c6:	b7d1                	j	ffffffffc020528a <schedule+0x58>
    if (proc != idleproc)
ffffffffc02052c8:	000b0797          	auipc	a5,0xb0
ffffffffc02052cc:	3e87b783          	ld	a5,1000(a5) # ffffffffc02b56b0 <idleproc>
ffffffffc02052d0:	f8f58fe3          	beq	a1,a5,ffffffffc020526e <schedule+0x3c>
        sched_class->enqueue(rq, proc);
ffffffffc02052d4:	00093783          	ld	a5,0(s2)
ffffffffc02052d8:	6088                	ld	a0,0(s1)
ffffffffc02052da:	6b9c                	ld	a5,16(a5)
ffffffffc02052dc:	9782                	jalr	a5
ffffffffc02052de:	bf41                	j	ffffffffc020526e <schedule+0x3c>
        intr_disable();
ffffffffc02052e0:	e1efb0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc02052e4:	4985                	li	s3,1
ffffffffc02052e6:	b78d                	j	ffffffffc0205248 <schedule+0x16>

ffffffffc02052e8 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052e8:	000b0797          	auipc	a5,0xb0
ffffffffc02052ec:	3b87b783          	ld	a5,952(a5) # ffffffffc02b56a0 <current>
}
ffffffffc02052f0:	43c8                	lw	a0,4(a5)
ffffffffc02052f2:	8082                	ret

ffffffffc02052f4 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052f4:	4501                	li	a0,0
ffffffffc02052f6:	8082                	ret

ffffffffc02052f8 <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc02052f8:	000b0797          	auipc	a5,0xb0
ffffffffc02052fc:	3507b783          	ld	a5,848(a5) # ffffffffc02b5648 <ticks>
ffffffffc0205300:	0027951b          	slliw	a0,a5,0x2
ffffffffc0205304:	9d3d                	addw	a0,a0,a5
ffffffffc0205306:	0015151b          	slliw	a0,a0,0x1
}
ffffffffc020530a:	8082                	ret

ffffffffc020530c <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc020530c:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc020530e:	1141                	addi	sp,sp,-16
ffffffffc0205310:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc0205312:	c7dff0ef          	jal	ffffffffc0204f8e <lab6_set_priority>
    return 0;
}
ffffffffc0205316:	60a2                	ld	ra,8(sp)
ffffffffc0205318:	4501                	li	a0,0
ffffffffc020531a:	0141                	addi	sp,sp,16
ffffffffc020531c:	8082                	ret

ffffffffc020531e <sys_putc>:
    cputchar(c);
ffffffffc020531e:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205320:	1141                	addi	sp,sp,-16
ffffffffc0205322:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205324:	ea9fa0ef          	jal	ffffffffc02001cc <cputchar>
}
ffffffffc0205328:	60a2                	ld	ra,8(sp)
ffffffffc020532a:	4501                	li	a0,0
ffffffffc020532c:	0141                	addi	sp,sp,16
ffffffffc020532e:	8082                	ret

ffffffffc0205330 <sys_kill>:
    return do_kill(pid);
ffffffffc0205330:	4108                	lw	a0,0(a0)
ffffffffc0205332:	a2bff06f          	j	ffffffffc0204d5c <do_kill>

ffffffffc0205336 <sys_yield>:
    return do_yield();
ffffffffc0205336:	9ddff06f          	j	ffffffffc0204d12 <do_yield>

ffffffffc020533a <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020533a:	6d14                	ld	a3,24(a0)
ffffffffc020533c:	6910                	ld	a2,16(a0)
ffffffffc020533e:	650c                	ld	a1,8(a0)
ffffffffc0205340:	6108                	ld	a0,0(a0)
ffffffffc0205342:	ba4ff06f          	j	ffffffffc02046e6 <do_execve>

ffffffffc0205346 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205346:	650c                	ld	a1,8(a0)
ffffffffc0205348:	4108                	lw	a0,0(a0)
ffffffffc020534a:	9d9ff06f          	j	ffffffffc0204d22 <do_wait>

ffffffffc020534e <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc020534e:	000b0797          	auipc	a5,0xb0
ffffffffc0205352:	3527b783          	ld	a5,850(a5) # ffffffffc02b56a0 <current>
    return do_fork(0, stack, tf);
ffffffffc0205356:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc0205358:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020535a:	6a0c                	ld	a1,16(a2)
ffffffffc020535c:	aedfe06f          	j	ffffffffc0203e48 <do_fork>

ffffffffc0205360 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205360:	4108                	lw	a0,0(a0)
ffffffffc0205362:	f3bfe06f          	j	ffffffffc020429c <do_exit>

ffffffffc0205366 <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc0205366:	000b0697          	auipc	a3,0xb0
ffffffffc020536a:	33a6b683          	ld	a3,826(a3) # ffffffffc02b56a0 <current>
syscall(void) {
ffffffffc020536e:	715d                	addi	sp,sp,-80
ffffffffc0205370:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205372:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc0205374:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205376:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc020537a:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020537c:	02d7ec63          	bltu	a5,a3,ffffffffc02053b4 <syscall+0x4e>
        if (syscalls[num] != NULL) {
ffffffffc0205380:	00002797          	auipc	a5,0x2
ffffffffc0205384:	3a078793          	addi	a5,a5,928 # ffffffffc0207720 <syscalls>
ffffffffc0205388:	00369613          	slli	a2,a3,0x3
ffffffffc020538c:	97b2                	add	a5,a5,a2
ffffffffc020538e:	639c                	ld	a5,0(a5)
ffffffffc0205390:	c395                	beqz	a5,ffffffffc02053b4 <syscall+0x4e>
            arg[0] = tf->gpr.a1;
ffffffffc0205392:	7028                	ld	a0,96(s0)
ffffffffc0205394:	742c                	ld	a1,104(s0)
ffffffffc0205396:	7830                	ld	a2,112(s0)
ffffffffc0205398:	7c34                	ld	a3,120(s0)
ffffffffc020539a:	6c38                	ld	a4,88(s0)
ffffffffc020539c:	f02a                	sd	a0,32(sp)
ffffffffc020539e:	f42e                	sd	a1,40(sp)
ffffffffc02053a0:	f832                	sd	a2,48(sp)
ffffffffc02053a2:	fc36                	sd	a3,56(sp)
ffffffffc02053a4:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053a6:	0828                	addi	a0,sp,24
ffffffffc02053a8:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02053aa:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053ac:	e828                	sd	a0,80(s0)
}
ffffffffc02053ae:	6406                	ld	s0,64(sp)
ffffffffc02053b0:	6161                	addi	sp,sp,80
ffffffffc02053b2:	8082                	ret
    print_trapframe(tf);
ffffffffc02053b4:	8522                	mv	a0,s0
ffffffffc02053b6:	e436                	sd	a3,8(sp)
ffffffffc02053b8:	f36fb0ef          	jal	ffffffffc0200aee <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02053bc:	000b0797          	auipc	a5,0xb0
ffffffffc02053c0:	2e47b783          	ld	a5,740(a5) # ffffffffc02b56a0 <current>
ffffffffc02053c4:	66a2                	ld	a3,8(sp)
ffffffffc02053c6:	00002617          	auipc	a2,0x2
ffffffffc02053ca:	13260613          	addi	a2,a2,306 # ffffffffc02074f8 <etext+0x1c54>
ffffffffc02053ce:	43d8                	lw	a4,4(a5)
ffffffffc02053d0:	06c00593          	li	a1,108
ffffffffc02053d4:	0b478793          	addi	a5,a5,180
ffffffffc02053d8:	00002517          	auipc	a0,0x2
ffffffffc02053dc:	15050513          	addi	a0,a0,336 # ffffffffc0207528 <etext+0x1c84>
ffffffffc02053e0:	86afb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02053e4 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02053e4:	9e3707b7          	lui	a5,0x9e370
ffffffffc02053e8:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_matrix_out_size+0xffffffff9e364ac1>
ffffffffc02053ea:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc02053ee:	02000513          	li	a0,32
ffffffffc02053f2:	9d0d                	subw	a0,a0,a1
}
ffffffffc02053f4:	00a7d53b          	srlw	a0,a5,a0
ffffffffc02053f8:	8082                	ret

ffffffffc02053fa <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053fa:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02053fc:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205400:	f022                	sd	s0,32(sp)
ffffffffc0205402:	ec26                	sd	s1,24(sp)
ffffffffc0205404:	e84a                	sd	s2,16(sp)
ffffffffc0205406:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205408:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020540c:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc020540e:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205412:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205416:	84aa                	mv	s1,a0
ffffffffc0205418:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc020541a:	03067d63          	bgeu	a2,a6,ffffffffc0205454 <printnum+0x5a>
ffffffffc020541e:	e44e                	sd	s3,8(sp)
ffffffffc0205420:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205422:	4785                	li	a5,1
ffffffffc0205424:	00e7d763          	bge	a5,a4,ffffffffc0205432 <printnum+0x38>
            putch(padc, putdat);
ffffffffc0205428:	85ca                	mv	a1,s2
ffffffffc020542a:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc020542c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020542e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205430:	fc65                	bnez	s0,ffffffffc0205428 <printnum+0x2e>
ffffffffc0205432:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205434:	00002797          	auipc	a5,0x2
ffffffffc0205438:	10c78793          	addi	a5,a5,268 # ffffffffc0207540 <etext+0x1c9c>
ffffffffc020543c:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020543e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205440:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0205444:	70a2                	ld	ra,40(sp)
ffffffffc0205446:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205448:	85ca                	mv	a1,s2
ffffffffc020544a:	87a6                	mv	a5,s1
}
ffffffffc020544c:	6942                	ld	s2,16(sp)
ffffffffc020544e:	64e2                	ld	s1,24(sp)
ffffffffc0205450:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205452:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205454:	03065633          	divu	a2,a2,a6
ffffffffc0205458:	8722                	mv	a4,s0
ffffffffc020545a:	fa1ff0ef          	jal	ffffffffc02053fa <printnum>
ffffffffc020545e:	bfd9                	j	ffffffffc0205434 <printnum+0x3a>

ffffffffc0205460 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205460:	7119                	addi	sp,sp,-128
ffffffffc0205462:	f4a6                	sd	s1,104(sp)
ffffffffc0205464:	f0ca                	sd	s2,96(sp)
ffffffffc0205466:	ecce                	sd	s3,88(sp)
ffffffffc0205468:	e8d2                	sd	s4,80(sp)
ffffffffc020546a:	e4d6                	sd	s5,72(sp)
ffffffffc020546c:	e0da                	sd	s6,64(sp)
ffffffffc020546e:	f862                	sd	s8,48(sp)
ffffffffc0205470:	fc86                	sd	ra,120(sp)
ffffffffc0205472:	f8a2                	sd	s0,112(sp)
ffffffffc0205474:	fc5e                	sd	s7,56(sp)
ffffffffc0205476:	f466                	sd	s9,40(sp)
ffffffffc0205478:	f06a                	sd	s10,32(sp)
ffffffffc020547a:	ec6e                	sd	s11,24(sp)
ffffffffc020547c:	84aa                	mv	s1,a0
ffffffffc020547e:	8c32                	mv	s8,a2
ffffffffc0205480:	8a36                	mv	s4,a3
ffffffffc0205482:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205484:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205488:	05500b13          	li	s6,85
ffffffffc020548c:	00003a97          	auipc	s5,0x3
ffffffffc0205490:	a94a8a93          	addi	s5,s5,-1388 # ffffffffc0207f20 <syscalls+0x800>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205494:	000c4503          	lbu	a0,0(s8)
ffffffffc0205498:	001c0413          	addi	s0,s8,1
ffffffffc020549c:	01350a63          	beq	a0,s3,ffffffffc02054b0 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02054a0:	cd0d                	beqz	a0,ffffffffc02054da <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02054a2:	85ca                	mv	a1,s2
ffffffffc02054a4:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054a6:	00044503          	lbu	a0,0(s0)
ffffffffc02054aa:	0405                	addi	s0,s0,1
ffffffffc02054ac:	ff351ae3          	bne	a0,s3,ffffffffc02054a0 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc02054b0:	5cfd                	li	s9,-1
ffffffffc02054b2:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc02054b4:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02054b8:	4b81                	li	s7,0
ffffffffc02054ba:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054bc:	00044683          	lbu	a3,0(s0)
ffffffffc02054c0:	00140c13          	addi	s8,s0,1
ffffffffc02054c4:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02054c8:	0ff5f593          	zext.b	a1,a1
ffffffffc02054cc:	02bb6663          	bltu	s6,a1,ffffffffc02054f8 <vprintfmt+0x98>
ffffffffc02054d0:	058a                	slli	a1,a1,0x2
ffffffffc02054d2:	95d6                	add	a1,a1,s5
ffffffffc02054d4:	4198                	lw	a4,0(a1)
ffffffffc02054d6:	9756                	add	a4,a4,s5
ffffffffc02054d8:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02054da:	70e6                	ld	ra,120(sp)
ffffffffc02054dc:	7446                	ld	s0,112(sp)
ffffffffc02054de:	74a6                	ld	s1,104(sp)
ffffffffc02054e0:	7906                	ld	s2,96(sp)
ffffffffc02054e2:	69e6                	ld	s3,88(sp)
ffffffffc02054e4:	6a46                	ld	s4,80(sp)
ffffffffc02054e6:	6aa6                	ld	s5,72(sp)
ffffffffc02054e8:	6b06                	ld	s6,64(sp)
ffffffffc02054ea:	7be2                	ld	s7,56(sp)
ffffffffc02054ec:	7c42                	ld	s8,48(sp)
ffffffffc02054ee:	7ca2                	ld	s9,40(sp)
ffffffffc02054f0:	7d02                	ld	s10,32(sp)
ffffffffc02054f2:	6de2                	ld	s11,24(sp)
ffffffffc02054f4:	6109                	addi	sp,sp,128
ffffffffc02054f6:	8082                	ret
            putch('%', putdat);
ffffffffc02054f8:	85ca                	mv	a1,s2
ffffffffc02054fa:	02500513          	li	a0,37
ffffffffc02054fe:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205500:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205504:	02500713          	li	a4,37
ffffffffc0205508:	8c22                	mv	s8,s0
ffffffffc020550a:	f8e785e3          	beq	a5,a4,ffffffffc0205494 <vprintfmt+0x34>
ffffffffc020550e:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0205512:	1c7d                	addi	s8,s8,-1
ffffffffc0205514:	fee79de3          	bne	a5,a4,ffffffffc020550e <vprintfmt+0xae>
ffffffffc0205518:	bfb5                	j	ffffffffc0205494 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020551a:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc020551e:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0205520:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0205524:	fd06071b          	addiw	a4,a2,-48
ffffffffc0205528:	24e56a63          	bltu	a0,a4,ffffffffc020577c <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc020552c:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020552e:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0205530:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0205534:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205538:	0197073b          	addw	a4,a4,s9
ffffffffc020553c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205540:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205542:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205546:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205548:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020554c:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0205550:	feb570e3          	bgeu	a0,a1,ffffffffc0205530 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0205554:	f60d54e3          	bgez	s10,ffffffffc02054bc <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0205558:	8d66                	mv	s10,s9
ffffffffc020555a:	5cfd                	li	s9,-1
ffffffffc020555c:	b785                	j	ffffffffc02054bc <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020555e:	8db6                	mv	s11,a3
ffffffffc0205560:	8462                	mv	s0,s8
ffffffffc0205562:	bfa9                	j	ffffffffc02054bc <vprintfmt+0x5c>
ffffffffc0205564:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0205566:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0205568:	bf91                	j	ffffffffc02054bc <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc020556a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020556c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205570:	00f74463          	blt	a4,a5,ffffffffc0205578 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205574:	1a078763          	beqz	a5,ffffffffc0205722 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0205578:	000a3603          	ld	a2,0(s4)
ffffffffc020557c:	46c1                	li	a3,16
ffffffffc020557e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205580:	000d879b          	sext.w	a5,s11
ffffffffc0205584:	876a                	mv	a4,s10
ffffffffc0205586:	85ca                	mv	a1,s2
ffffffffc0205588:	8526                	mv	a0,s1
ffffffffc020558a:	e71ff0ef          	jal	ffffffffc02053fa <printnum>
            break;
ffffffffc020558e:	b719                	j	ffffffffc0205494 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0205590:	000a2503          	lw	a0,0(s4)
ffffffffc0205594:	85ca                	mv	a1,s2
ffffffffc0205596:	0a21                	addi	s4,s4,8
ffffffffc0205598:	9482                	jalr	s1
            break;
ffffffffc020559a:	bded                	j	ffffffffc0205494 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020559c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020559e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055a2:	00f74463          	blt	a4,a5,ffffffffc02055aa <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02055a6:	16078963          	beqz	a5,ffffffffc0205718 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc02055aa:	000a3603          	ld	a2,0(s4)
ffffffffc02055ae:	46a9                	li	a3,10
ffffffffc02055b0:	8a2e                	mv	s4,a1
ffffffffc02055b2:	b7f9                	j	ffffffffc0205580 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc02055b4:	85ca                	mv	a1,s2
ffffffffc02055b6:	03000513          	li	a0,48
ffffffffc02055ba:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc02055bc:	85ca                	mv	a1,s2
ffffffffc02055be:	07800513          	li	a0,120
ffffffffc02055c2:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055c4:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02055c8:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055ca:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055cc:	bf55                	j	ffffffffc0205580 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02055ce:	85ca                	mv	a1,s2
ffffffffc02055d0:	02500513          	li	a0,37
ffffffffc02055d4:	9482                	jalr	s1
            break;
ffffffffc02055d6:	bd7d                	j	ffffffffc0205494 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02055d8:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055dc:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02055de:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02055e0:	bf95                	j	ffffffffc0205554 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc02055e2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055e4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055e8:	00f74463          	blt	a4,a5,ffffffffc02055f0 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc02055ec:	12078163          	beqz	a5,ffffffffc020570e <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc02055f0:	000a3603          	ld	a2,0(s4)
ffffffffc02055f4:	46a1                	li	a3,8
ffffffffc02055f6:	8a2e                	mv	s4,a1
ffffffffc02055f8:	b761                	j	ffffffffc0205580 <vprintfmt+0x120>
            if (width < 0)
ffffffffc02055fa:	876a                	mv	a4,s10
ffffffffc02055fc:	000d5363          	bgez	s10,ffffffffc0205602 <vprintfmt+0x1a2>
ffffffffc0205600:	4701                	li	a4,0
ffffffffc0205602:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205606:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205608:	bd55                	j	ffffffffc02054bc <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020560a:	000d841b          	sext.w	s0,s11
ffffffffc020560e:	fd340793          	addi	a5,s0,-45
ffffffffc0205612:	00f037b3          	snez	a5,a5
ffffffffc0205616:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020561a:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc020561e:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205620:	008a0793          	addi	a5,s4,8
ffffffffc0205624:	e43e                	sd	a5,8(sp)
ffffffffc0205626:	100d8c63          	beqz	s11,ffffffffc020573e <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc020562a:	12071363          	bnez	a4,ffffffffc0205750 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020562e:	000dc783          	lbu	a5,0(s11)
ffffffffc0205632:	0007851b          	sext.w	a0,a5
ffffffffc0205636:	c78d                	beqz	a5,ffffffffc0205660 <vprintfmt+0x200>
ffffffffc0205638:	0d85                	addi	s11,s11,1
ffffffffc020563a:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020563c:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205640:	000cc563          	bltz	s9,ffffffffc020564a <vprintfmt+0x1ea>
ffffffffc0205644:	3cfd                	addiw	s9,s9,-1
ffffffffc0205646:	008c8d63          	beq	s9,s0,ffffffffc0205660 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020564a:	020b9663          	bnez	s7,ffffffffc0205676 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc020564e:	85ca                	mv	a1,s2
ffffffffc0205650:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205652:	000dc783          	lbu	a5,0(s11)
ffffffffc0205656:	0d85                	addi	s11,s11,1
ffffffffc0205658:	3d7d                	addiw	s10,s10,-1
ffffffffc020565a:	0007851b          	sext.w	a0,a5
ffffffffc020565e:	f3ed                	bnez	a5,ffffffffc0205640 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0205660:	01a05963          	blez	s10,ffffffffc0205672 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0205664:	85ca                	mv	a1,s2
ffffffffc0205666:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020566a:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc020566c:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc020566e:	fe0d1be3          	bnez	s10,ffffffffc0205664 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205672:	6a22                	ld	s4,8(sp)
ffffffffc0205674:	b505                	j	ffffffffc0205494 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205676:	3781                	addiw	a5,a5,-32
ffffffffc0205678:	fcfa7be3          	bgeu	s4,a5,ffffffffc020564e <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc020567c:	03f00513          	li	a0,63
ffffffffc0205680:	85ca                	mv	a1,s2
ffffffffc0205682:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205684:	000dc783          	lbu	a5,0(s11)
ffffffffc0205688:	0d85                	addi	s11,s11,1
ffffffffc020568a:	3d7d                	addiw	s10,s10,-1
ffffffffc020568c:	0007851b          	sext.w	a0,a5
ffffffffc0205690:	dbe1                	beqz	a5,ffffffffc0205660 <vprintfmt+0x200>
ffffffffc0205692:	fa0cd9e3          	bgez	s9,ffffffffc0205644 <vprintfmt+0x1e4>
ffffffffc0205696:	b7c5                	j	ffffffffc0205676 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0205698:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020569c:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc020569e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02056a0:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02056a4:	8fb9                	xor	a5,a5,a4
ffffffffc02056a6:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056aa:	02d64563          	blt	a2,a3,ffffffffc02056d4 <vprintfmt+0x274>
ffffffffc02056ae:	00003797          	auipc	a5,0x3
ffffffffc02056b2:	9ca78793          	addi	a5,a5,-1590 # ffffffffc0208078 <error_string>
ffffffffc02056b6:	00369713          	slli	a4,a3,0x3
ffffffffc02056ba:	97ba                	add	a5,a5,a4
ffffffffc02056bc:	639c                	ld	a5,0(a5)
ffffffffc02056be:	cb99                	beqz	a5,ffffffffc02056d4 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc02056c0:	86be                	mv	a3,a5
ffffffffc02056c2:	00000617          	auipc	a2,0x0
ffffffffc02056c6:	20e60613          	addi	a2,a2,526 # ffffffffc02058d0 <etext+0x2c>
ffffffffc02056ca:	85ca                	mv	a1,s2
ffffffffc02056cc:	8526                	mv	a0,s1
ffffffffc02056ce:	0d8000ef          	jal	ffffffffc02057a6 <printfmt>
ffffffffc02056d2:	b3c9                	j	ffffffffc0205494 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056d4:	00002617          	auipc	a2,0x2
ffffffffc02056d8:	e8c60613          	addi	a2,a2,-372 # ffffffffc0207560 <etext+0x1cbc>
ffffffffc02056dc:	85ca                	mv	a1,s2
ffffffffc02056de:	8526                	mv	a0,s1
ffffffffc02056e0:	0c6000ef          	jal	ffffffffc02057a6 <printfmt>
ffffffffc02056e4:	bb45                	j	ffffffffc0205494 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02056e6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056e8:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02056ec:	00f74363          	blt	a4,a5,ffffffffc02056f2 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc02056f0:	cf81                	beqz	a5,ffffffffc0205708 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc02056f2:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02056f6:	02044b63          	bltz	s0,ffffffffc020572c <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02056fa:	8622                	mv	a2,s0
ffffffffc02056fc:	8a5e                	mv	s4,s7
ffffffffc02056fe:	46a9                	li	a3,10
ffffffffc0205700:	b541                	j	ffffffffc0205580 <vprintfmt+0x120>
            lflag ++;
ffffffffc0205702:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205704:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205706:	bb5d                	j	ffffffffc02054bc <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0205708:	000a2403          	lw	s0,0(s4)
ffffffffc020570c:	b7ed                	j	ffffffffc02056f6 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc020570e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205712:	46a1                	li	a3,8
ffffffffc0205714:	8a2e                	mv	s4,a1
ffffffffc0205716:	b5ad                	j	ffffffffc0205580 <vprintfmt+0x120>
ffffffffc0205718:	000a6603          	lwu	a2,0(s4)
ffffffffc020571c:	46a9                	li	a3,10
ffffffffc020571e:	8a2e                	mv	s4,a1
ffffffffc0205720:	b585                	j	ffffffffc0205580 <vprintfmt+0x120>
ffffffffc0205722:	000a6603          	lwu	a2,0(s4)
ffffffffc0205726:	46c1                	li	a3,16
ffffffffc0205728:	8a2e                	mv	s4,a1
ffffffffc020572a:	bd99                	j	ffffffffc0205580 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc020572c:	85ca                	mv	a1,s2
ffffffffc020572e:	02d00513          	li	a0,45
ffffffffc0205732:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0205734:	40800633          	neg	a2,s0
ffffffffc0205738:	8a5e                	mv	s4,s7
ffffffffc020573a:	46a9                	li	a3,10
ffffffffc020573c:	b591                	j	ffffffffc0205580 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc020573e:	e329                	bnez	a4,ffffffffc0205780 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205740:	02800793          	li	a5,40
ffffffffc0205744:	853e                	mv	a0,a5
ffffffffc0205746:	00002d97          	auipc	s11,0x2
ffffffffc020574a:	e13d8d93          	addi	s11,s11,-493 # ffffffffc0207559 <etext+0x1cb5>
ffffffffc020574e:	b5f5                	j	ffffffffc020563a <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205750:	85e6                	mv	a1,s9
ffffffffc0205752:	856e                	mv	a0,s11
ffffffffc0205754:	08a000ef          	jal	ffffffffc02057de <strnlen>
ffffffffc0205758:	40ad0d3b          	subw	s10,s10,a0
ffffffffc020575c:	01a05863          	blez	s10,ffffffffc020576c <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0205760:	85ca                	mv	a1,s2
ffffffffc0205762:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205764:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0205766:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205768:	fe0d1ce3          	bnez	s10,ffffffffc0205760 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020576c:	000dc783          	lbu	a5,0(s11)
ffffffffc0205770:	0007851b          	sext.w	a0,a5
ffffffffc0205774:	ec0792e3          	bnez	a5,ffffffffc0205638 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205778:	6a22                	ld	s4,8(sp)
ffffffffc020577a:	bb29                	j	ffffffffc0205494 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020577c:	8462                	mv	s0,s8
ffffffffc020577e:	bbd9                	j	ffffffffc0205554 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205780:	85e6                	mv	a1,s9
ffffffffc0205782:	00002517          	auipc	a0,0x2
ffffffffc0205786:	dd650513          	addi	a0,a0,-554 # ffffffffc0207558 <etext+0x1cb4>
ffffffffc020578a:	054000ef          	jal	ffffffffc02057de <strnlen>
ffffffffc020578e:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205792:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0205796:	00002d97          	auipc	s11,0x2
ffffffffc020579a:	dc2d8d93          	addi	s11,s11,-574 # ffffffffc0207558 <etext+0x1cb4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020579e:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02057a0:	fda040e3          	bgtz	s10,ffffffffc0205760 <vprintfmt+0x300>
ffffffffc02057a4:	bd51                	j	ffffffffc0205638 <vprintfmt+0x1d8>

ffffffffc02057a6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057a6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02057a8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057ac:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057ae:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057b0:	ec06                	sd	ra,24(sp)
ffffffffc02057b2:	f83a                	sd	a4,48(sp)
ffffffffc02057b4:	fc3e                	sd	a5,56(sp)
ffffffffc02057b6:	e0c2                	sd	a6,64(sp)
ffffffffc02057b8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02057ba:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057bc:	ca5ff0ef          	jal	ffffffffc0205460 <vprintfmt>
}
ffffffffc02057c0:	60e2                	ld	ra,24(sp)
ffffffffc02057c2:	6161                	addi	sp,sp,80
ffffffffc02057c4:	8082                	ret

ffffffffc02057c6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02057c6:	00054783          	lbu	a5,0(a0)
ffffffffc02057ca:	cb81                	beqz	a5,ffffffffc02057da <strlen+0x14>
    size_t cnt = 0;
ffffffffc02057cc:	4781                	li	a5,0
        cnt ++;
ffffffffc02057ce:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02057d0:	00f50733          	add	a4,a0,a5
ffffffffc02057d4:	00074703          	lbu	a4,0(a4)
ffffffffc02057d8:	fb7d                	bnez	a4,ffffffffc02057ce <strlen+0x8>
    }
    return cnt;
}
ffffffffc02057da:	853e                	mv	a0,a5
ffffffffc02057dc:	8082                	ret

ffffffffc02057de <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02057de:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057e0:	e589                	bnez	a1,ffffffffc02057ea <strnlen+0xc>
ffffffffc02057e2:	a811                	j	ffffffffc02057f6 <strnlen+0x18>
        cnt ++;
ffffffffc02057e4:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057e6:	00f58863          	beq	a1,a5,ffffffffc02057f6 <strnlen+0x18>
ffffffffc02057ea:	00f50733          	add	a4,a0,a5
ffffffffc02057ee:	00074703          	lbu	a4,0(a4)
ffffffffc02057f2:	fb6d                	bnez	a4,ffffffffc02057e4 <strnlen+0x6>
ffffffffc02057f4:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02057f6:	852e                	mv	a0,a1
ffffffffc02057f8:	8082                	ret

ffffffffc02057fa <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02057fa:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02057fc:	0005c703          	lbu	a4,0(a1)
ffffffffc0205800:	0585                	addi	a1,a1,1
ffffffffc0205802:	0785                	addi	a5,a5,1
ffffffffc0205804:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205808:	fb75                	bnez	a4,ffffffffc02057fc <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020580a:	8082                	ret

ffffffffc020580c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020580c:	00054783          	lbu	a5,0(a0)
ffffffffc0205810:	e791                	bnez	a5,ffffffffc020581c <strcmp+0x10>
ffffffffc0205812:	a01d                	j	ffffffffc0205838 <strcmp+0x2c>
ffffffffc0205814:	00054783          	lbu	a5,0(a0)
ffffffffc0205818:	cb99                	beqz	a5,ffffffffc020582e <strcmp+0x22>
ffffffffc020581a:	0585                	addi	a1,a1,1
ffffffffc020581c:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0205820:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205822:	fef709e3          	beq	a4,a5,ffffffffc0205814 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205826:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020582a:	9d19                	subw	a0,a0,a4
ffffffffc020582c:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020582e:	0015c703          	lbu	a4,1(a1)
ffffffffc0205832:	4501                	li	a0,0
}
ffffffffc0205834:	9d19                	subw	a0,a0,a4
ffffffffc0205836:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205838:	0005c703          	lbu	a4,0(a1)
ffffffffc020583c:	4501                	li	a0,0
ffffffffc020583e:	b7f5                	j	ffffffffc020582a <strcmp+0x1e>

ffffffffc0205840 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205840:	ce01                	beqz	a2,ffffffffc0205858 <strncmp+0x18>
ffffffffc0205842:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205846:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205848:	cb91                	beqz	a5,ffffffffc020585c <strncmp+0x1c>
ffffffffc020584a:	0005c703          	lbu	a4,0(a1)
ffffffffc020584e:	00f71763          	bne	a4,a5,ffffffffc020585c <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0205852:	0505                	addi	a0,a0,1
ffffffffc0205854:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205856:	f675                	bnez	a2,ffffffffc0205842 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205858:	4501                	li	a0,0
ffffffffc020585a:	8082                	ret
ffffffffc020585c:	00054503          	lbu	a0,0(a0)
ffffffffc0205860:	0005c783          	lbu	a5,0(a1)
ffffffffc0205864:	9d1d                	subw	a0,a0,a5
}
ffffffffc0205866:	8082                	ret

ffffffffc0205868 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205868:	a021                	j	ffffffffc0205870 <strchr+0x8>
        if (*s == c) {
ffffffffc020586a:	00f58763          	beq	a1,a5,ffffffffc0205878 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc020586e:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205870:	00054783          	lbu	a5,0(a0)
ffffffffc0205874:	fbfd                	bnez	a5,ffffffffc020586a <strchr+0x2>
    }
    return NULL;
ffffffffc0205876:	4501                	li	a0,0
}
ffffffffc0205878:	8082                	ret

ffffffffc020587a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020587a:	ca01                	beqz	a2,ffffffffc020588a <memset+0x10>
ffffffffc020587c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020587e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205880:	0785                	addi	a5,a5,1
ffffffffc0205882:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205886:	fef61de3          	bne	a2,a5,ffffffffc0205880 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020588a:	8082                	ret

ffffffffc020588c <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020588c:	ca19                	beqz	a2,ffffffffc02058a2 <memcpy+0x16>
ffffffffc020588e:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205890:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205892:	0005c703          	lbu	a4,0(a1)
ffffffffc0205896:	0585                	addi	a1,a1,1
ffffffffc0205898:	0785                	addi	a5,a5,1
ffffffffc020589a:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020589e:	feb61ae3          	bne	a2,a1,ffffffffc0205892 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02058a2:	8082                	ret
