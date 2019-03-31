echo "compiling..."
gfortran -c -fdefault-real-8 globalVars.f90
gfortran -c -fdefault-real-8 integration.f90
gfortran -c -fdefault-real-8 tester.f90
gfortran -g tester.o globalVars.o integration.o -o tester 

echo "running..."
./tester > output && cat output

echo "plotting..."

echo "All tasks omplete."