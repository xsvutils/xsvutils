package buffer

import (
	"fmt"
	"os"
	"syscall"
)

func Buffer() {

	epfd, err := syscall.EpollCreate1(0)
	if err != nil {
		fmt.Fprintln(os.Stderr, "epoll_create:", err)
		os.Exit(1)
	}

	{
		var event syscall.EpollEvent
		event.Events = syscall.EPOLLIN
		err := syscall.EpollCtl(epfd, syscall.EPOLL_CTL_ADD, 0, &event);
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}
	{
		var event syscall.EpollEvent
		event.Events = syscall.EPOLLOUT
		err := syscall.EpollCtl(epfd, syscall.EPOLL_CTL_ADD, 1, &event);
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}

	var stdin_closed bool = false;
	var stdout_closed bool = false;

	var buffer []byte = make([]byte, 40 * 1024 * 1024);
	var offset1 int = 0;
	var offset2 int = 0;

	for {
		if stdin_closed && stdout_closed {
			break
		}

		var events [2]syscall.EpollEvent
		nevents, err := syscall.EpollWait(epfd, events[:], -1)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}

		for i := 0; i < nevents; i++ {
			if (events[i].Events & syscall.EPOLLIN) != 0 {
				nbytes, err := syscall.Read(0, buffer[offset1:])
				if err != nil {
					fmt.Fprintln(os.Stderr, "syscall.Read:", err)
					os.Exit(1)
				}
				offset1 += nbytes

			} else if (events[i].Events & syscall.EPOLLOUT) != 0 {
				nbytes, err := syscall.Write(1, buffer[offset2:offset1])
				if err != nil {
					os.Exit(0) // 出力先がなくなった場合はそのまま終了する
				}
				offset2 += nbytes
				if offset1 == offset2 {
					offset1 = 0
					offset2 = 0
					if stdin_closed {
						stdout_closed = true
					}
				}

			} else if events[i].Events == syscall.EPOLLHUP {
				if events[i].Fd == 0 {
					stdin_closed = true;
				} else {
					stdout_closed = true;
				}

				{
					var event syscall.EpollEvent
					err := syscall.EpollCtl(epfd, syscall.EPOLL_CTL_DEL, int(events[i].Fd), &event);
					if err != nil {
						fmt.Fprintln(os.Stderr, err)
						os.Exit(1)
					}
				}
			}
		}
	}

}
