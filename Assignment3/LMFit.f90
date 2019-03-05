!module containing code for bracketed minimum search by golden sections
!compile with:
!gfortran -c -fdefault-real-8 LMFit.f90 -llapack

module LMFit
implicit none

! Interface for calling the f&df functions
interface
	!real and real array to real; forall block needs pure
	pure function RnRA2R(c, x)
		real, intent(in) :: c(:), x
		real :: RnRA2R
	end function RnRA2R
	
	!real and real array to real array; forall block needs pure
	pure function RnRA2RA(c, x)
		real, intent(in) :: c(:), x
		real :: RnRA2RA(size(c))
	end function RnRA2RA
end interface

contains

!Use Levenberg  Marquardt algorithm to minimize Chi2
function levenMarq(x, y, f, df, c0, lambda0, eps, maxRuns) result(c)
	procedure(RnRA2R) :: f
	procedure(RnRA2RA) :: df
	real, intent(in) :: x(:), y(:), c0(:), lambda0, eps
	integer, intent(in) :: maxRuns
	real, dimension(size(c0)) :: c, cNext, JTxDiff
	real, dimension(size(x)) :: diff, diffNext
	real, dimension(size(c0), size(c0)) :: g, JTxJ
	real :: J(size(x), size(c0)), JT(size(c0),size(x))
	real :: sumSq, sumSqNext, lambda, epsNext
	integer i, runs
	real, parameter :: lambdaFactor = 1.1
	
	!Starting point
	lambda = lambda0
	c = c0
	forall (i=1:size(x)) diff(i) = y(i) - f(c, x(i))
	sumSq = 0.5 * sum(diff**2.0)

	do runs = 1, maxRuns
		forall (i=1:size(x)) JT(:, i) = df(c, x(i))
		J = transpose(JT)
		JTxJ = matmul(JT, J)
		JTxDiff = matmul(JT, diff)
		
		g = JTxJ
		forall (i=1:size(c0)) g(i,i) = (1.0 + lambda) * g(i,i)
		
		cNext = c + lss(g, JTxDiff)
		forall (i=1:size(x)) diffNext(i) = y(i) - f(cNext, x(i))
		sumSqNext = 0.5 * sum(diffNext**2.0)
		epsNext = abs(sumSqNext - sumSq)
		
		!take next coeffs if sumSq is smaller
		if (sumSqNext < sumSq) then
			c = cNext
			diff = diffNext
			sumSq = sumSqNext
			lambda = lambda / lambdaFactor
		else
			lambda = lambda * lambdaFactor
		end if
		
		if (epsNext <= eps) exit
	end do
end function

! Use LSS to solve A(lss) = B
function lss(A, B)
	real, intent(in) :: A(:,:), B(:)
	real :: lss(size(A,2))
	real :: ACopy(size(A,1), size(A,2)), BCopy(size(B,1))
	real :: sig(size(A,2)), work(6*size(A,2))
	real :: rcond
	integer :: numPoints, n, rank, LWork, info
	
	numPoints = size(A,1)
	n = size(A,2)
	LWork = size(work)
	ACopy = A
	BCopy = B
	call dgelss(numPoints, n, 1, ACopy, numPoints, BCopy, numPoints, sig, rcond, rank, work, LWork, info)
	
	if (info /= 0) call abort
	lss = BCopy(1:size(lss))
end function

! basis is b_a(x)=cos(2pi*a*x)
pure function basis(a, x)
	integer, intent(in) :: a
	real, intent(in) :: x
	real :: basis
	real, parameter :: pi = 3.14159265358979323846264338327950288419716939937510

	basis = cos(2 * pi * a * x)
end function

! non-linear model for fit f3 = e^(sum(cb)) + const
pure function f3(c, x)
	real, intent(in) :: c(:), x
	real :: f3, b(size(c) - 1)
	integer :: a, n
	n = size(c) - 1
	
	forall (a=1:n) b(a) = basis(a-1 ,x)
	f3 = exp(sum(c(1:n) * b)) + c(n+1)
end function

pure function df3(c, x)
	real, intent(in) :: c(:), x
	real :: df3(size(c)), b(size(c) -1), factor
	integer :: a, n
	n = size(c) - 1
	
	forall (a=1:n) b(a) = basis(a-1, x)
	df3(1:n) = exp(sum(c(1:n) * b)) * b
	df3(n+1) = 1.0
end function
end module