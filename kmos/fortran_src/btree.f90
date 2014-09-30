module btree

    use kind_values

    implicit none
    type ::  binary_tree
        real(kind=rdouble), allocatable, dimension(:) :: rate_constants
        integer(kind=iint), allocatable, dimension(:) :: procs, memaddrs
        integer(kind=iint) :: levels, total_length, filled
    end type


contains

    function btree_init(n) result(self)
        type(binary_tree) :: self
        integer(kind=iint), intent(in) :: n


        self%levels = ceiling(log(real(n)) / log(2.) + 1)
        self%total_length = 2 ** self%levels

        allocate(self%rate_constants(self%total_length))
        self%rate_constants = 0.

        allocate(self%procs(self%total_length/2))
        self%procs = 0

        allocate(self%memaddrs(self%total_length/2))
        self%memaddrs = 0

        self%filled = 0

    end function btree_init


    subroutine btree_destroy(self)
        type(binary_tree),  intent(inout) :: self

        deallocate(self%rate_constants)
        deallocate(self%procs)
        deallocate(self%memaddrs)

    end subroutine btree_destroy


    subroutine btree_repr(self)
        type(binary_tree)  :: self
        integer(kind=iint) :: a, b, n

        print *, "PROCS", self%procs
        print *, "MEMADDR", self%memaddrs
        print *, "RATES"
        do n = 0, (self%levels - 1)
        a = 2 ** n
        b = 2 ** (n + 1) - 1
        print *, self%rate_constants(a:b)
        enddo

    end subroutine btree_repr


    subroutine btree_add(self, rate_constant, proc, site)
        type(binary_tree) :: self
        integer(kind=iint), intent(in) :: site
        real(kind=rdouble) :: rate_constant
        integer(kind=iint) :: proc

        integer(kind=iint) :: pos

        if(self%filled * 2 + 1 > self%total_length)then
            print *, "btree_add"
            print *, "Tree overfull!!! Quit."
            stop
        endif

        pos = self%total_length / 2 + self%filled
        self%rate_constants(pos) = rate_constant
        call btree_update(self, pos)

        self%memaddrs(site) = pos
        self%filled = self%filled + 1
        self%procs(self%filled) = proc

    end subroutine btree_add


    subroutine btree_del(self, site)
        type(binary_tree) :: self
        integer(kind=iint), intent(in) :: site
        integer(kind=iint) :: pos, filled

        pos = self%memaddrs(site)
        filled = self%filled + self%total_length / 2

        ! move deleted new data field
        self%rate_constants(pos) = &
            self%rate_constants(filled)
        self%rate_constants(filled) = 0.

        print *, "FILLED", self%filled
        print *, "PROCS_POS", pos - (self%total_length/2)

        self%procs(pos - (self%total_length/2)) = self%procs(filled)

        ! update tree structure
        call btree_update(self, pos)
        call btree_update(self, filled)

        ! decrease tree structure
        self%filled = self%filled - 1

    end subroutine btree_del


    subroutine btree_replace(self, site, new_rate)
        type(binary_tree) :: self
        real(kind=rdouble), intent(in) :: new_rate
        integer(kind=iint), intent(in) :: site
        integer(kind=iint) :: pos

        pos = self%memaddrs(site)
        self%rate_constants(pos) = new_rate
        call btree_update(self, pos)

    end subroutine btree_replace


    subroutine btree_update(self, pos)
        type(binary_tree) :: self
        integer(kind=iint), intent(in) :: pos
        integer(kind=iint) :: pos_

        pos_ = pos
        do while (pos_ > 1)
        pos_ = pos_ / 2
        self%rate_constants(pos_) = self%rate_constants(2 * pos_) + self%rate_constants(2 * pos_ + 1)

        end do
    end subroutine btree_update


    subroutine btree_pick(self, x, n)
        type(binary_tree), intent(in) :: self
        real(kind=rdouble), intent(in) :: x
        integer(kind=iint), intent(out) :: n
        real(kind=rdouble) :: x_


        x_ = x

        n = 1
        do while (n < self%total_length / 2)
        if (x_ < self%rate_constants(n)) then
            n = 2 * n
        else
            x_ = x_ - self%rate_constants(n)
            n = 2 * n + 2
        endif
        enddo

        if(x_ > self%rate_constants(n))then
            n = n + 1
        endif

        n = self%procs(1 + n - self%total_length / 2)

    end subroutine btree_pick

end module btree
