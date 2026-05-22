%% Calculate EI models
% dataset with the following variables:
% - ID (optional)
% - Sex (coded M/F)
% - Age
% - Weight
% - Length
% - Muscle
% - EI
dataset = readtable('\\tsclient\O\NEURO-KNF\research_data_echo\Spierecho normaalwaarde project 2021-2022-2023\Pooled_r123.xlsx'); % add path
%dataset.BMI = dataset.Weight ./ (dataset.Length ./ 100) .^ 2;
dataset.BMI = dataset.Length;

muscles = unique(dataset.Muscle);

for i = 1:numel(muscles)

    modelData = dataset(strcmp(dataset.Muscle, muscles{i}), :);

    % centre and scale all contineous predictor variables
    EImdls.meanAge(i) = mean(modelData.Age);
    EImdls.sdAge(i) = std(modelData.Age);
    EImdls.meanBMI(i) = mean(modelData.BMI);
    EImdls.sdBMI(i) = std(modelData.BMI);

    modelData.cAge2 = (modelData.Age - EImdls.meanAge(i)) .^ 2;
    modelData.cBMI2 = (modelData.BMI - EImdls.meanBMI(i)) .^ 2;

    EImdls.meanAge2(i) = mean(modelData.cAge2);
    EImdls.sdAge2(i) = std(modelData.cAge2);
    EImdls.meanBMI2(i) = mean(modelData.cBMI2);
    EImdls.sdBMI2(i) = std(modelData.cBMI2);

    modelData.csAge = (modelData.Age - EImdls.meanAge(i)) / EImdls.sdAge(i);
    modelData.csBMI = (modelData.BMI - EImdls.meanBMI(i)) / EImdls.sdBMI(i);
    modelData.csAge2 = (modelData.cAge2 - EImdls.meanAge2(i)) / EImdls.sdAge2(i);
    modelData.csBMI2 = (modelData.cBMI2 - EImdls.meanBMI2(i)) / EImdls.sdBMI2(i);

    % Fit initial model
    disp(muscles{i});
    EImdls.Muscle{i} = muscles{i};
    EImdls.Model{i} = stepwiselm(modelData, 'EI~1+csAge+csAge2+Sex+csBMI+csBMI2', ...
        'ResponseVar', 'EI', ...
        'PredictorVars', {'csAge', 'csAge2', 'csBMI', 'csBMI2', 'Sex'}, ...
        'CategoricalVar', 'Sex', ...
        'Criterion', 'aic');

    % find outliers and refit model without outliers
    EImdls.outliers{i} = EImdls.Model{i}.Diagnostics.cooksDistance > (20 * median(EImdls.Model{i}.Diagnostics.cooksDistance));
    EImdls.Model{i} = stepwiselm(modelData, 'EI~1+csAge+csAge2+Sex+csBMI+csBMI2', ...
        'ResponseVar', 'EI', ...
        'PredictorVars', {'csAge', 'csAge2', 'csBMI', 'csBMI2', 'Sex'}, ...
        'CategoricalVar', 'Sex', ...
        'Criterion', 'aic', ...
        'Exclude', EImdls.outliers{i});

end

%% visualize EI models
clc

% index of muscles
i = 2;

modelData = EImdls.Model{i}.Variables;
% uncomment to use mean BMI for visualization, to get rid of chaotic plots
% modelData.csBMI(:) = mean(modelData.csBMI);
% modelData.csBMI2(:) = mean(modelData.csBMI2);

% predict using data on which the model was fitted
[pred, CI] = predict(EImdls.Model{i}, modelData, 'Prediction', 'observation');
% [pred, CI] = predict(EImdls.Model{i});

% Male
colorCode = [0 0.4470 0.7410];
plot(modelData.Age(strcmp(modelData.Sex, 'M')), modelData.EI(strcmp(modelData.Sex, 'M')), 'o', 'Color', colorCode)
hold on
plot(modelData.Age(strcmp(modelData.Sex, 'M') & ~EImdls.outliers{i}), pred(strcmp(modelData.Sex, 'M') & ~EImdls.outliers{i}), '*', 'Color', colorCode)
upper = sortrows([modelData.Age(strcmp(modelData.Sex, 'M') & ~EImdls.outliers{i}), CI(strcmp(modelData.Sex, 'M') & ~EImdls.outliers{i}, 2)], 1);
lower = sortrows([modelData.Age(strcmp(modelData.Sex, 'M') & ~EImdls.outliers{i}), CI(strcmp(modelData.Sex, 'M') & ~EImdls.outliers{i}, 1)], 1);
X=[upper(:, 1); flip(lower(:, 1))];
Y=[upper(:, 2); flip(lower(:, 2))];
fill(X, Y, colorCode, 'faceAlpha', 0.2, 'EdgeColor', 'none');

% Female
colorCode = [0.8500 0.3250 0.0980];
plot(modelData.Age(strcmp(modelData.Sex, 'F')), modelData.EI(strcmp(modelData.Sex, 'F')), 'o', 'Color', colorCode)
plot(modelData.Age(strcmp(modelData.Sex, 'F') & ~EImdls.outliers{i}), pred(strcmp(modelData.Sex, 'F') & ~EImdls.outliers{i}), '*', 'Color', colorCode)
upper = sortrows([modelData.Age(strcmp(modelData.Sex, 'F') & ~EImdls.outliers{i}), CI(strcmp(modelData.Sex, 'F') & ~EImdls.outliers{i}, 2)], 1);
lower = sortrows([modelData.Age(strcmp(modelData.Sex, 'F') & ~EImdls.outliers{i}), CI(strcmp(modelData.Sex, 'F') & ~EImdls.outliers{i}, 1)], 1);
X=[upper(:, 1); flip(lower(:, 1))];
Y=[upper(:, 2); flip(lower(:, 2))];
fill(X, Y, colorCode, 'faceAlpha', 0.2, 'EdgeColor', 'none');

% Outliers
plot(modelData.Age(EImdls.outliers{i}), modelData.EI(EImdls.outliers{i}), '*', 'Color', [0 0 0])
hold off

title([EImdls.Muscle{i} ' echogenicity (R2adj = ' num2str(EImdls.Model{i}.Rsquared.Adjusted) ')'])
xlabel('Age (y)')
ylabel('Mean pixel gray value (AU)')

EImdls.Model{i}

%% Calculate thickness models
% dataset with the following variables:
% - ID (optional)
% - Sex (coded M/F)
% - Dominance (coded Dominant/Non-Dominant, optional)
% - Age
% - Weight
% - Length
% - Muscle
% - EI
dataset = readtable('.xlsx'); % add path
dataset.BMI = dataset.Weight ./ (dataset.Length ./ 100) .^ 2;

muscles = unique(dataset.Muscle);

for i = 1:numel(muscles)

    modelData = dataset(strcmp(dataset.Muscle, muscles{i}), :);

    % centre and scale all contineous predictor variables
    THmdls.meanAge(i) = mean(modelData.Age);
    THmdls.sdAge(i) = std(modelData.Age);
    THmdls.meanBMI(i) = mean(modelData.BMI);
    THmdls.sdBMI(i) = std(modelData.BMI);

    modelData.cAge2 = (modelData.Age - THmdls.meanAge(i)) .^ 2;
    modelData.cBMI2 = (modelData.BMI - THmdls.meanBMI(i)) .^ 2;

    THmdls.meanAge2(i) = mean(modelData.cAge2);
    THmdls.sdAge2(i) = std(modelData.cAge2);
    THmdls.meanBMI2(i) = mean(modelData.cBMI2);
    THmdls.sdBMI2(i) = std(modelData.cBMI2);

    modelData.csAge = (modelData.Age - THmdls.meanAge(i)) / THmdls.sdAge(i);
    modelData.csBMI = (modelData.BMI - THmdls.meanBMI(i)) / THmdls.sdBMI(i);
    modelData.csAge2 = (modelData.cAge2 - THmdls.meanAge2(i)) / THmdls.sdAge2(i);
    modelData.csBMI2 = (modelData.cBMI2 - THmdls.meanBMI2(i)) / THmdls.sdBMI2(i);

    disp(muscles{i});
    THmdls.Muscle{i} = muscles{i};

   if size(unique(modelData.Dominance), 1) > 1
             
       % Fit initial model
       THmdls.Model{i} = stepwiselm(modelData, 'Thickness~1+csAge+csAge2+Sex+csBMI+csBMI2+Dominance', ...
            'ResponseVar', 'Thickness', ...
            'PredictorVars', {'csAge', 'csAge2', 'csBMI', 'csBMI2', 'Sex', 'Dominance'}, ...
            'CategoricalVar', {'Sex', 'Dominance'}, ...
            'Criterion', 'aic');
       
       % find outliers and refit model without outliers
       THmdls.outliers{i} = THmdls.Model{i}.Diagnostics.cooksDistance > (20 * median(THmdls.Model{i}.Diagnostics.cooksDistance));
       THmdls.Model{i} = stepwiselm(modelData, 'Thickness~1+csAge+csAge2+Sex+csBMI+csBMI2+Dominance', ...
            'ResponseVar', 'Thickness', ...
            'PredictorVars', {'csAge', 'csAge2', 'csBMI', 'csBMI2', 'Sex', 'Dominance'}, ...
            'CategoricalVar', {'Sex', 'Dominance'}, ...
            'Criterion', 'aic', ...
            'Exclude', THmdls.outliers{i});

   else
       
       % Fit initial model
       THmdls.Model{i} = stepwiselm(modelData, 'Thickness~1+csAge+csAge2+Sex+csBMI+csBMI2', ...
            'ResponseVar', 'Thickness', ...
            'PredictorVars', {'csAge', 'csAge2', 'csBMI', 'csBMI2', 'Sex'}, ...
            'CategoricalVar', 'Sex', ...
            'Criterion', 'aic');

       % find outliers and refit model without outliers
       THmdls.outliers{i} = THmdls.Model{i}.Diagnostics.cooksDistance > (20 * median(THmdls.Model{i}.Diagnostics.cooksDistance));
       THmdls.Model{i} = stepwiselm(modelData, 'Thickness~1+csAge+csAge2+Sex+csBMI+csBMI2', ...
            'ResponseVar', 'Thickness', ...
            'PredictorVars', {'csAge', 'csAge2', 'csBMI', 'csBMI2', 'Sex'}, ...
            'CategoricalVar', 'Sex', ...
            'Criterion', 'aic', ...
            'Exclude', THmdls.outliers{i});
       
    end

end

%% visualize TH models
clc

% index of muscles
i = 1;

modelData = THmdls.Model{i}.Variables;

% uncomment to use mean BMI for visualization, to get rid of chaotic plots
% modelData.csBMI(:) = mean(modelData.csBMI);
% modelData.csBMI2(:) = mean(modelData.csBMI2);

% predict using data on which the model was fitted
[pred, CI] = predict(THmdls.Model{i}, modelData, 'Prediction', 'observation');

% Male
%subplot(1, 2, 1)
colorCode = [0 0.4470 0.7410];
plot(modelData.Age(strcmp(modelData.Sex, 'M')), modelData.Thickness(strcmp(modelData.Sex, 'M')), 'o', 'Color', colorCode)
hold on
plot(modelData.Age(strcmp(modelData.Sex, 'M') & ~THmdls.outliers{i}), pred(strcmp(modelData.Sex, 'M') & ~THmdls.outliers{i}), '*', 'Color', colorCode)
upper = sortrows([modelData.Age(strcmp(modelData.Sex, 'M') & ~THmdls.outliers{i}), CI(strcmp(modelData.Sex, 'M') & ~THmdls.outliers{i}, 2)], 1);
lower = sortrows([modelData.Age(strcmp(modelData.Sex, 'M') & ~THmdls.outliers{i}), CI(strcmp(modelData.Sex, 'M') & ~THmdls.outliers{i}, 1)], 1);
X=[upper(:, 1); flip(lower(:, 1))];
Y=[upper(:, 2); flip(lower(:, 2))];
fill(X, Y, colorCode, 'faceAlpha', 0.2, 'EdgeColor', 'none');

% Female
colorCode = [0.8500 0.3250 0.0980];
plot(modelData.Age(strcmp(modelData.Sex, 'F')), modelData.Thickness(strcmp(modelData.Sex, 'F')), 'o', 'Color', colorCode)
plot(modelData.Age(strcmp(modelData.Sex, 'F') & ~THmdls.outliers{i}), pred(strcmp(modelData.Sex, 'F') & ~THmdls.outliers{i}), '*', 'Color', colorCode)
upper = sortrows([modelData.Age(strcmp(modelData.Sex, 'F') & ~THmdls.outliers{i}), CI(strcmp(modelData.Sex, 'F') & ~THmdls.outliers{i}, 2)], 1);
lower = sortrows([modelData.Age(strcmp(modelData.Sex, 'F') & ~THmdls.outliers{i}), CI(strcmp(modelData.Sex, 'F') & ~THmdls.outliers{i}, 1)], 1);
X=[upper(:, 1); flip(lower(:, 1))];
Y=[upper(:, 2); flip(lower(:, 2))];
fill(X, Y, colorCode, 'faceAlpha', 0.2, 'EdgeColor', 'none');

% Outliers
plot(modelData.Age(THmdls.outliers{i}), modelData.Thickness(THmdls.outliers{i}), '*', 'Color', [0 0 0])

hold off

title([THmdls.Muscle{i} ' Thickness (R2adj = ' num2str(THmdls.Model{i}.Rsquared.Adjusted) ')'])
xlabel('Age (y)')
ylabel('Muscle thickness (cm)')

THmdls.Model{i}

