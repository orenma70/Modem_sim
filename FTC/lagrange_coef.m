function P=lagrange coef (order)
  if mod(order,2)
    inx=- (order-1)/2: (order-1)/2;
  else
    inx=- order/2: -order/2+order-1;
  end

P=zeros (order);
C=zeros (1,order);
for r=l:order
inx_temp=inx;
inx temp(r)=[];
P(r,:)=poly(inx_temp);
C(r)=1;
for k=l:order-1
C(r)=C(r)* (inx(r)-inx_temp(k));
end
P(r,:)=P(r,:)/C(r);
end

