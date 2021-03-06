####################################################################
########## Configuration file for CIFAR-10 classification ##########
####################################################################

# dataset specification configuration
dataset = 'cifar10'

# image specification configuration
w, h = 32, 32
uw, uh = 36, 36
channels = 3

# training specification configuration
epochs = 200
batch_size = 32
dropout_rate = 0.0
keep_prob = 1-dropout_rate
weight_decay = 0.0005

# model specification configuration
model = 'vggnet'
activate = 'relu'
resume = False

# collection specification configuration
MOVING_AVERAGE_DECAY = 0.9
BN_DECAY = 0.9
BN_EPSILON = 1e-3
CONV_WEIGHT_DECAY = 5e-4
RESNET_VARIABLES = 'resnet_variables'

# step specification configuration
display_iter = (batch_size*75*float(128/batch_size))
step1 = (80*((50000/batch_size)+1))+1
step2 = (120*((50000/batch_size)+1))+1
step3 = (160*((50000/batch_size)+1))+1
