clc
clear
close all
%{
speech signal v
far-end echoed signal dhat
using LMS

step 1: generate impulse response of room by FIR filter
step 2: get sample near-end(speech signal) and play it
step 3: get sample far-end(echoed signal)and filter it using room impulse
response
step 4: pass the actual signal (unfiltered_near+filtered_far+noise) to
LMS filter
step 5: measure ERLE, the amount that the echo is attenuated (in dB)
%}

%Step 1: get room impluse response
M = 4001;
fs = 8000;    %sampling rate (voice frequency ranges from 300 - 3400 Hz)
[B,A] = cheby2(4,20,[0.1 0.7]);
Hd = dfilt.df2t([zeros(1,6) B],A);
hFVT = fvtool(Hd);  % Analyze the filter
set(hFVT, 'Color', [1 1 1])

H = filter(Hd,log(0.99*rand(1,M)+0.01).* ...
    sign(randn(1,M)).*exp(-0.002*(1:M)));
H = H/norm(H)*4;    % Room Impulse Response
%
figure
%
plot(0:1/fs:0.5,H);
xlabel('Time [sec]');
ylabel('Amplitude');
title('Room Impulse Response');
set(gcf, 'Color', [1 1 1])

%step 2: get sample near-end(speech signal) and play it
load nearspeech
n = 1:length(v);
t = n/fs;
%
figure
%
plot(t,v);
axis([0 33.5 -1 1]);
xlabel('Time [sec]');
ylabel('Amplitude');
title('Near-End Speech Signal');
set(gcf, 'Color', [1 1 1])
pause
disp('Playing Near-End Speech Signal') %v is near-end
%p8 = audioplayer(v,fs);  don;t play near and far speech
%playblocking(p8);

%{
step 3: get sample far-end(echoed signal)and filter it using room 
impulseresponse
-speech without near-end signal present
-sound picked up by microphone after bounching in the room
%}

load farspeech
x = x(1:length(x));
dhat = filter(H,1,x);           %filtered far speech, using room impulse H
%
figure
%
plot(t,dhat);
axis([0 33.5 -1 1]);
xlabel('Time [sec]');
ylabel('Amplitude');
title('Far-End Echoed Speech Signal');
set(gcf, 'Color', [1 1 1])
pause                         %pause before playing
disp('Playing Far-End Speech Signal') %dhat is far-end
%p8 = audioplayer(dhat,fs);
%playblocking(p8);

%{
step 4: pass the actual signal (unfiltered_near+filtered_far+noise) to
LMS filter
-actual signal contains near-end,far-end and noise
-only near-end is transmitted back to far-end listener, cancels out
-far-end speech
%}
d = dhat + v+0.001*randn(length(v),1); %linear comb of filtered_far+unfiltered_near+noise
%
figure
%
plot(t,d);                             %d is linear comb (microphone signal)
axis([0 33.5 -1 1]);
xlabel('Time [sec]');
ylabel('Amplitude');
title('Microphone Signal');
set(gcf, 'Color', [1 1 1])
pause                            %pause before playing
disp('Playing Microphone Signal')
p8 = audioplayer(d,fs);
playblocking(p8);

mu = 0.025;                     %sys parameters for LMS
W0 = zeros(1,2048);
del = 0.01;
lam = 0.98;
x = x(1:length(W0)*floor(length(x)/length(W0)));
d = d(1:length(W0)*floor(length(d)/length(W0)));

%The FDAF filter, useful for identifying long impulse response
% Construct the Frequency-Domain Adaptive Filter
hFDAF = adaptfilt.fdaf(2048,mu,1,del,lam);   %e is after the filter
[y,e] = filter(hFDAF,x,d);
n = 1:length(e);
t = n/fs;
%
figure
%
pos = get(gcf,'Position');  % gcf = current figure handle
set(gcf,'Position',[pos(1), pos(2)-100,pos(3),(pos(4)+85)])
subplot(3,1,1);
plot(t,v(n),'g');
axis([0 33.5 -1 1]);
ylabel('Amplitude');
title('Near-End Speech Signal');
subplot(3,1,2);
plot(t,d(n),'b');
axis([0 33.5 -1 1]);
ylabel('Amplitude');
title('Microphone Signal');
subplot(3,1,3);
plot(t,e(n),'r');
axis([0 33.5 -1 1]);
xlabel('Time [sec]');
ylabel('Amplitude');
title('Output of Acoustic Echo Canceller');
set(gcf, 'Color', [1 1 1])
pause                                        %pause before playing
disp('Playing mixed Speech Signal after filter mu =0.025')
%p8 = audioplayer(e/max(abs(e)),fs);
%playblocking(p8);

%step 5: measure ERLE, the amount that the echo is attenuated (in dB)
%35 dB -> 56 times less than original far-end
%larger step-size -> faster convergence but worst performance (misadjustament)
Hd2 = dfilt.dffir(ones(1,1000)); %returns a discrete-time, direct-form 
                                 %finite impulse response (FIR) filter, Hd2, 
                                 %with numerator coefficients, ones(1:1000)
setfilter(hFVT,Hd2);

erle = filter(Hd2,(e-v(1:length(e))).^2)./ ...
    (filter(Hd2,dhat(1:length(e)).^2));
erledB = -10*log10(erle);
%
figure
%
plot(t,erledB);
axis([0 33.5 0 40]);
xlabel('Time [sec]');
ylabel('ERLE [dB]');
title('Echo Return Loss Enhancement');
set(gcf, 'Color', [1 1 1])

newmu = 0.04;
set(hFDAF,'StepSize',newmu);
[y,e2] = filter(hFDAF,x,d);
%
figure
%
pos = get(gcf,'Position');
set(gcf,'Position',[pos(1), pos(2)-100,pos(3),(pos(4)+85)])
subplot(3,1,1);
plot(t,v(n),'g');
axis([0 33.5 -1 1]);
ylabel('Amplitude');
title('Near-End Speech Signal');
subplot(3,1,2);
plot(t,e(n),'r');
axis([0 33.5 -1 1]);
ylabel('Amplitude');
title('Output of Acoustic Echo Canceller, \mu = 0.025');
subplot(3,1,3);
plot(t,e2(n),'r');
axis([0 33.5 -1 1]);
xlabel('Time [sec]');
ylabel('Amplitude');
title('Output of Acoustic Echo Canceller, \mu = 0.04');
set(gcf, 'Color', [1 1 1])
pause                                        %pause before playing
disp('Playing mixed Speech Signal after filter mu =0.04')
p8 = audioplayer(e2/max(abs(e2)),fs);
playblocking(p8);

%close;
%
figure
%
erle2 = filter(Hd2,(e2-v(1:length(e2))).^2)./...
    (filter(Hd2,dhat(1:length(e2)).^2));
erle2dB = -10*log10(erle2);
plot(t,[erledB erle2dB]);
axis([0 33.5 0 40]);
xlabel('Time [sec]');
ylabel('ERLE [dB]');
title('Echo Return Loss Enhancements');
legend('FDAF, \mu = 0.025','FDAF, \mu = 0.04');
set(gcf, 'Color', [1 1 1])
