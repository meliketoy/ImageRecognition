# 1. Batch Normalization
2015 arXiv, ICML2015 published paper :
Batch Normalization:Accelerating Deep Network Training by Reducing Internal Covariance Shift.
See the paper [here](http://jmlr.org/proceedings/papers/v37/ioffe15.pdf)

### a. Motivation
Basically, batch normalization is a technique to prevent Gradient Vanishing/Exploding.

Until 2015, there were several attempts in order to tackle the Gradient Vanishing/Exploding problem,
such as modifying activation functions(ReLU etc.), careful initialization, small learning rate, and etc.
Though these methods have contributed in resolving the problem, they were not a radical solution.
The authors of Batch Normalization aimed to tackle this problem in a more direct way,
resulting stabilized training process and accelerated training speed.


The authors of the paper above thought that basically the Gradient Vanishing problem is occurred
due to 'Internal Covariance Shift'.

### b. Internal Covariance Shift
Internal Covariance Shift is a phenomenon in which each network layers and activation recieves a 
different input distribution.

In order to resolve this problem, we simply need to normalize each inputs to make
mean = 0, standard deviation = 1

This could be obtained by the 'whitening' process.
The 'whitening' process basically makes each input features uncorrelated while making its variance=1.

The problem is that in order to do 'whitening', we need to calculate the covariance matrix and the inverse.
This results in a lot of calculation load, nonetheless ignoring some of the parameter's effectiveness.

For an example, let's assume that we take an input 'u' and output 'x=u+b'.
```bash
x = u+b
```
Our goal is to optimize the bias b. When conducting 'whitening', we first calculate the mean.

```bash
E(x) = E(u) + b
```

when subtracting this from the original x, we obtain
```bash
x - E(x) = u+b - (E(u)+b) = u-E(u)
```

As you can see, the whitening process resulted in ignoring the most important variable we need to optimize.
Moreover, whitening also conducts the scaling process of the standard deviation, which will make these
problems worse and worse.

### c. Approaches
In order to overcome the disadvantages of 'whitening' process and reduce internal covariance shift,
they approached the problem as below.

- Assume that each features are already uncorrelated, and normalize only individual features by its mean and variance.
- Simply fixating the mean, variance to 0,1 will ironically nuterize the non-linearity of the activation function. For example, if the input to a sigmoid activation function is fixed to mean=0, stddev=1, the curve will appear as a linear function. Therefore, it scales by gamma, and shifts by beta the normliazed values.
- Mini-batch approach. The normalization is proceeded with the mean and variance of the mini-batch, not the entire training data.

### d. Application
When applying batch normalization, we add the batch\_norm layer right before the hidden layer, so the
inputs are correctly modified before entering the activation function.

# 2. Moving Averages
In statistics, a moving average (=rolling average, running average) is a calculation to analyze data points by creating series of averages of different subsets of the full data set.

Some training algorithms, such as Gradient Descent and Momentum often benefit from maintaining a moving average of variables during optimization. Using the moving averages for evaluations often improve results significantly.

[More about Moving averages](https://www.tensorflow.org/versions/r0.11/api_docs/python/train.html#moving-averages)

# 3. Global Contrast Normalization
Computes the mean and standard deviation of all the pixels in the image and subtracts from each pixels.
Also, devides each pixel by the global standard deviation.

The whitening(PCA, ZCA) works better when your data is mean centered.

# 4. ZCA whitening
We use PCA to reduce the dimension of the data. There is a closely related preprocessing step called whitening.
If we are training on images, the raw input is redundant, since adjacent pixel values are highly correlated.
The goal of whitening is to make the input less redundant; more formally, our learning algorithms
sees a training input where the features are less correlated with each other, and the features have the same variance.

[More about whitening](http://ufldl.stanford.edu/wiki/index.php/Whitening)
