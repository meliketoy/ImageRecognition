export netType='wide-resnet'
export depth=40
export width=10
export dataset='imagenet'
export data='gen/catdog'
export save=logs/catdog/${netType}
export experiment_number=1
mkdir -p $save
mkdir -p modelState

th main.lua \
-dataset ${dataset} \
-data ${data} \
-netType ${netType} \
-nGPU 2 \
-batchSize 8 \
-nClasses 2 \
-resetClassifier true \
-top5_display false \
-testOnly false \
-depth ${depth} \
-widen_factor ${width} \
| tee $save/train_log${experiment_number}.txt
