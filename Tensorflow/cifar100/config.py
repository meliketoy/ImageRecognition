####################################################################
########## Configuration file for CIFAR-10 classification ##########
####################################################################

# dataset specification configuration
dataset = 'cifar100'

# image specification configuration
w, h = 32, 32
uw, uh = 36, 36
channels = 3

# training specification configuration
epochs = 200
batch_size = 128
dropout_rate = 0.3
keep_prob = 1-dropout_rate
lr_decay = 0.0005

# model specification configuration
model = 'resnet28x10'
resume = False

# step specification configuration
display_iter = (batch_size*75*float(128/batch_size))
step1 = (60*((50000/batch_size)+1))+1
step2 = (120*((50000/batch_size)+1))+1
step3 = (160*((50000/batch_size)+1))+1
