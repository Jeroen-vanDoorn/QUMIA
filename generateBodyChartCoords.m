clear all
clc

im = imread('BodyChart.jpg');
load('bodyChartCoords.mat');

% 'Biceps brachii', 'Biceps femoris', 'Deltoideus', 'Depressor anguli oris', 'Diafragma', 'Digastricus',
% 'Extensors underarm', 'Flexor carpi radialis', 'Flexor digitorum profundus', 'Gastrocnemius medial head',
% 'Geniohyoideus', 'Intercostals', 'Interosseus dorsalis I', 'Masseter', 'Obliquus ext abdominus', 
% 'Obliquus int abdominus', 'Orbicularis oris', 'Paraspinaal lumbal', 'Paraspinaal thoracal', 'Peroneus tertius', 
% 'Rectus abdominis', 'Rectus femoris', 'Serratus anterior', 'Soleus', 'Sterno cleido', 'Temporalis' 
% 'Tibialis anterior', 'Transversus abdominus', 'Trapezius', 'Triceps', 'Vastus lateralis', 
% 'Zygomaticus major', 'Zygomaticus minor'
muscle = 'Flexor carpi radialis';

if ~isempty(find(strcmp(coords.muscle, muscle)))

    i = find(strcmp(coords.muscle, muscle));

else

    i = size(coords.muscle, 2) + 1;

end

for k = 1:size(coords.muscle, 2)

    im(coords.maskR{k}) = 150;
    im(coords.maskL{k}) = 50;

end

coords.muscle{i} = muscle;
imagesc(im)
h = impoly();
maskR = createMask(h);
maskL = zeros(size(maskR));

[y, x] = find(maskR);

% front muscle
if max(x) < 150

    for j = 1:numel(x)

        maskL(y(j), 73 + (73 - x(j))) = 1;

    end

% back muscle
else

    for j = 1:numel(x)
    
        maskL(y(j), 226 - (x(j) - 226)) = 1;

    end

end

coords.maskR{i} = repmat(maskR, [1, 1, 3]);
coords.maskL{i} = repmat(logical(maskL), [1, 1, 3]);

%%
delete(h)
save('bodyChartCoords.mat', 'coords')
close all
