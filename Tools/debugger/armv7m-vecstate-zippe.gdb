#
# Assorted ARMv7M macros
#
# Originally provided by "zippe" on ##stm32.
# Search for "vecstate" on github if you want to see other authors/copiers
# stoner tldr: (gdb) source this_file_yo; vecstate

echo Loading ARMv7M GDB macros.  Use 'help armv7m' for more information.\n

define armv7m
	echo Use 'help armv7m' for more information.\n
end

document armv7m
. Various macros for working with the ARMv7M family of processors.
.
.    vecstate
.        Print information about the current exception handling state.
.
. Use 'help <macro>' for more specific help.
end


define vecstate
	set $icsr  = *(unsigned *)0xe000ed04
	set $vect  = $icsr & 0x1ff
	# irqs vs exceptions
	set $vect_irqnum = $vect - 16
	set $pend  = ($icsr & 0x1ff000) >> 12
	set $shcsr = *(unsigned *)0xe000ed24
	set $cfsr  = *(unsigned *)0xe000ed28
	set $mmfsr = $cfsr & 0xff
	set $bfsr  = ($cfsr >> 8) & 0xff
	set $ufsr  = ($cfsr >> 16) & 0xffff
	set $hfsr  = *(unsigned *)0xe000ed2c
	set $bfar  = *(unsigned *)0xe000ed38
	set $mmfar = *(unsigned *)0xe000ed34

	if $vect < 15

		if $hfsr != 0
			printf "HardFault:"
			if $hfsr & (1<<1)
				printf " due to vector table read fault\n"
			end
			if $hfsr & (1<<30)
				printf " forced due to escalated or disabled configurable fault (see below)\n"
			end
			if $hfsr & (1<<31)
				printf " due to an unexpected debug event\n"
			end
		end
		if $mmfsr != 0
			printf "MemManage:"
			if $mmfsr & (1<<5)
				printf " during lazy FP state save"
			end
			if $mmfsr & (1<<4)
				printf " during exception entry"
			end
			if $mmfsr & (1<<3)
				printf " during exception return"
			end
			if $mmfsr & (1<<1)
				printf " during data access"
			end
			if $mmfsr & (1<<0)
				printf " during instruction prefetch"
			end
			if $mmfsr & (1<<7)
				printf " accessing 0x%08x", $mmfar
			end
			printf "\n"
		end
		if $bfsr != 0
			printf "BusFault:"
			if $bfsr & (1<<2)
				printf " (imprecise)"
			end
			if $bfsr & (1<<1)
				printf " (precise)"
			end
			if $bfsr & (1<<5)
				printf " during lazy FP state save"
			end
			if $bfsr & (1<<4)
				printf " during exception entry"
			end
			if $bfsr & (1<<3)
				printf " during exception return"
			end
			if $bfsr & (1<<0)
				printf " during instruction prefetch"
			end
			if $bfsr & (1<<7)
				printf " accessing 0x%08x", $bfar
			end
			printf "\n"
		end
		if $ufsr != 0
			printf "UsageFault"
			if $ufsr & (1<<9)
				printf " due to divide-by-zero"
			end
			if $ufsr & (1<<8)
				printf " due to unaligned memory access"
			end
			if $ufsr & (1<<4)
				printf " due to stack overflow"
			end
			if $ufsr & (1<<3)
				printf " due to access to disabled/absent coprocessor"
			end
			if $ufsr & (1<<2)
				printf " due to a bad EXC_RETURN value"
			end
			if $ufsr & (1<<1)
				printf " due to bad T or IT bits in EPSR"
			end
			if $ufsr & (1<<0)
				printf " due to executing an undefined instruction"
			end
			printf "\n"
		end
	else
		if $vect >= 15
			printf "Handling vector %u (irq: %u)\n", $vect, $vect_irqnum
		end
	end
	if ((unsigned)$lr & 0xf0000000) == 0xf0000000
		if ($lr & 1)
			printf "exception frame is on MSP\n"
			#set $frame_ptr = (unsigned *)$msp
			set $frame_ptr = (unsigned *)$sp
		else
			printf "exception frame is on PSP, backtrace may not be possible\n"
			#set $frame_ptr = (unsigned *)$psp
			set $frame_ptr = (unsigned *)$sp
		end
		printf "  r0: %08x  r1: %08x  r2: %08x  r3: %08x\n", $frame_ptr[0], $frame_ptr[1], $frame_ptr[2], $frame_ptr[3]
		printf "  r4: %08x  r5: %08x  r6: %08x  r7: %08x\n", $r4, $r5, $r6, $r7
		printf "  r8: %08x  r9: %08x r10: %08x r11: %08x\n", $r8, $r9, $r10, $r11
		printf " r12: %08x  lr: %08x  pc: %08x PSR: %08x\n", $frame_ptr[4], $frame_ptr[5], $frame_ptr[6], $frame_ptr[7]

		# Swap to the context of the faulting code and try to print a backtrace
		set $saved_sp = $sp
		if $lr & 0x10
			set $sp = $frame_ptr + (8 * 4)
		else
			set $sp = $frame_ptr + (26 * 4)
		end
		set $saved_lr = $lr
		set $lr = $frame_ptr[5]
		set $saved_pc = $pc
		set $pc = $frame_ptr[6]
		bt
		set $sp = $saved_sp
		set $lr = $saved_lr
		set $pc = $saved_pc
	else
		printf "(not currently in exception handler)\n"
	end
end

document vecstate
.    vecstate
.        Print information about the current exception handling state.
end
