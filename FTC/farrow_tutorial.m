close all

Fs=1996.8;
BW=1400;
rel_bw=BW/Fs;
w_p=10; % 10 bits
farrow_len=7;
farrow_order=5;

M=32;


sb_freq_factor=0.95;

pass_freq=rel_bw/(2*M);
stop_freq=sb_freq_factor*(1/M-pass_freq);

lpf=firls(M*farrow_len,2*[0 pass_freq stop_freq .5],[1 1 0 0],[1 200]);
plot(linspace(-farrow_len/2,farrow_len/2,M*farrow_len+1),lpf);

mu=-1/2:1/M:1/2;
p=zeros(farrow_len,farrow_order);

for i=1:farrow_len
  lpf_i=lpf((i-1)*M+1:M*i+1);
  hold on
  plot(-(farrow_len+1)/2+i+mu,lpf_i,'r.')
  p(i,:)=polyfit(mu,lpf_i,farrow_order-1);
end

P=fliplr(p);

Pg2unity=floor( 1/max(abs(P(:))));
fp_gain=Pg2unity*2^(w_p-1);
Pint=round(fp_gain*P/1.5657)







