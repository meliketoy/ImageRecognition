--
--  (Author) Bumsoo Kim, 2016
--  Github : https://github.com/meliketoy/ImageRecognition
--
--  Korea University, Data-Mining Lab
--  Image Recognition Torch Implementation
--
--  The training loop and learning rate schedule
--

local optim = require 'optim'

local M = {}
local Trainer = torch.class('resnet.Trainer', M)
local elapsed_time = 0

function Trainer:__init(model, criterion, opt, optimState)
   self.model = model
   self.criterion = criterion
   self.optimState = optimState or {
      learningRate = opt.LR,
      learningRateDecay = 0.0,
      momentum = opt.momentum,
      nesterov = true,
      dampening = 0.0,
      weightDecay = opt.weightDecay,
   }
   self.opt = opt
   self.params, self.gradParams = model:getParameters()
end

function Trainer:train(epoch, dataloader)
   -- Trains the model for a single epoch
   self.optimState.learningRate = self:learningRate(epoch)

   local timer = torch.Timer()
   local dataTimer = torch.Timer()

   local function feval()
      return self.criterion.output, self.gradParams
   end

   local trainSize = dataloader:size()
   local top1Sum, top5Sum, lossSum = 0.0, 0.0, 0.0
   local N = 0

   print('=> Training epoch # ' .. epoch)
   -- set the batch norm to training mode
   self.model:training()
   for n, sample in dataloader:run() do
      local dataTime = dataTimer:time().real

      -- Copy input and target to the GPU
      self:copyInputs(sample)

      local output = self.model:forward(self.input):float()
      local batchSize = output:size(1)
      local loss = self.criterion:forward(self.model.output, self.target)

      self.model:zeroGradParameters()
      self.criterion:backward(self.model.output, self.target)
      self.model:backward(self.input, self.criterion.gradInput)

      optim.sgd(feval, self.params, self.optimState)

      local top1, top5 = self:computeScore(output, sample.target, 1)
      top1Sum = top1Sum + top1*batchSize
      top5Sum = top5Sum + top5*batchSize
      lossSum = lossSum + loss*batchSize
      N = N + batchSize
      elapsed_time = elapsed_time + timer:time().real + dataTime

      if(n % self.opt.display_iter == 0) then
          if self.opt.top5_display then
              print((' | [#%3d][%3d/%d]    Time %.3f  Loss %1.4f  Top1 %7.3f%s  Top5 %7.3f%s')
              :format(epoch, n, trainSize, timer:time().real + dataTime, loss, top1, '%', top5, '%'))
          else
              print((' | [#%3d][%3d/%d]    Time %.3f  Loss %1.4f  Top1 %7.3f%s')
              :format(epoch, n, trainSize, timer:time().real + dataTime, loss, top1, '%'))
          end
      end

      -- check that the storage didn't get changed do to an unfortunate getParameters call
      assert(self.params:storage() == self.model:parameters()[1]:storage())

      timer:reset()
      dataTimer:reset()
   end

   return top1Sum / N, top5Sum / N, lossSum / N
end

function Trainer:test(epoch, dataloader)
   -- Computes the top-1 and top-5 err on the validation set

   local timer = torch.Timer()
   local dataTimer = torch.Timer()
   local size = dataloader:size()

   local nCrops = self.opt.tenCrop and 10 or 1
   local top1Sum, top5Sum = 0.0, 0.0
   local N = 0

   self.model:evaluate()
   for n, sample in dataloader:run() do
      local dataTime = dataTimer:time().real

      -- Copy input and target to the GPU
      self:copyInputs(sample)

      local output = self.model:forward(self.input):float()
      local batchSize = output:size(1) / nCrops
      local loss = self.criterion:forward(self.model.output, self.target)

      local top1, top5 = self:computeScore(output, sample.target, nCrops)
      top1Sum = top1Sum + top1*batchSize
      top5Sum = top5Sum + top5*batchSize
      N = N + batchSize
      elpased_time = elapsed_time + timer:time().real + dataTime

      timer:reset()
      dataTimer:reset()
   end
   self.model:training()

   if self.opt.testOnly then
      return top1Sum / N, top5Sum / N
   end

   if self.opt.top5_display then
      print((' * Finished epoch # %d     top1: %7.3f  top5: %6.2f%s'):format(epoch, top1Sum / N, top5Sum / N, '%'))
      print(' * Elapsed time: '..math.floor(elapsed_time/3600)..' hours '..
                                 math.floor((elapsed_time%3600)/60)..' minutes '..
                                 math.floor((elapsed_time%3600)%60)..' seconds\n')
 
   else
      print((' * Finished epoch # %d     top1: %7.3f%s'):format(epoch, top1Sum / N, '%'))
      print(' * Elapsed time: '..math.floor(elapsed_time/3600)..' hours '..
                                 math.floor((elapsed_time%3600)/60)..' minutes '..
                                 math.floor((elapsed_time%3600)%60)..' seconds\n')
   end

   return top1Sum / N, top5Sum / N
end

function Trainer:computeScore(output, target, nCrops)
   if nCrops > 1 then
      -- Sum over crops
      output = output:view(output:size(1) / nCrops, nCrops, output:size(2))
         --:exp()
         :sum(2):squeeze(2)
   end

   -- Coputes the top1 and top5 error rate
   local batchSize = output:size(1)

   local _ , predictions = output:float():sort(2, true) -- descending

   -- Find which predictions match the target
   local correct = predictions:eq(
      target:long():view(batchSize, 1):expandAs(output))

   -- Top-1 score
   local top1 = (correct:narrow(2, 1, 1):sum() / batchSize)

   -- Top-5 score, if there are at least 5 classes
   local len = math.min(5, correct:size(2))
   local top5 = (correct:narrow(2, 1, len):sum() / batchSize)

   return top1 * 100, top5 * 100
end

function Trainer:copyInputs(sample)
   -- Copies the input to a CUDA tensor, if using 1 GPU, or to pinned memory,
   -- if using DataParallelTable. The target is always copied to a CUDA tensor
   self.input = self.input or (self.opt.nGPU == 1
      and torch.CudaTensor()
      or cutorch.createCudaHostTensor())
   self.target = self.target or torch.CudaTensor()--or (torch.CudaLongTensor and torch.CudaLongTensor()or torch.CudaTensor())
   self.input:resize(sample.input:size()):copy(sample.input)
   self.target:resize(sample.target:size()):copy(sample.target)
end

function Trainer:learningRate(epoch)
   -- Training schedule
   local decay = 0
   if self.opt.dataset == 'imagenet' then
      decay = math.floor((epoch - 1) / 30)
   elseif self.opt.dataset == 'catdog' then
      decay = math.floor((epoch - 1) / 30)
   elseif self.opt.dataset == 'cifar10' then
      decay = epoch >= 160 and 3 or epoch >= 120 and 2 or epoch >= 60 and 1 or 0
   elseif self.opt.dataset == 'cifar100' then
      decay = epoch >= 160 and 3 or epoch >= 120 and 2 or epoch >= 60 and 1 or 0
   end
   return self.opt.LR * math.pow(0.2, decay)
end

function Trainer:weightDecay(epoch)
    local decay = 0
    if self.opt.dataset == 'cifar10' then
        decay = epoch >= 160 and 5 or 1
    elseif self.opt.dataset == 'cifar100' then
        decay = epoch >= 160 and 5 or 1
    else
        decay = 1
    end

    return self.opt.weightDecay / decay
end

return M.Trainer
