data = load("mppt_dataset.mat");
X = data.inputs';
Y = data.targets';

net = fitnet(10, "trainlm");
net.divideParam.trainRatio = .7;
net.divideParam.valRatio = .15;
net.divideParam.testRatio = .15;

[net, tr] = train(net, X, Y);
figure;
plotperform(tr)
figure;
plotregression(Y, net(X));
gensim(net)



