% Main Script Section
close all
N = 1e4;
t = 0:N-1;
Fs = 1966.08e6;
fin = 20e6;
fout = 1996.8e6;
m = fout/fin;
in = sin(2*pi*fin/Fs*t);
out = lagrange_ftc(in, m);

plot(in)
hold on
plot(out)
