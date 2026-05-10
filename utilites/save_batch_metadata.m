function save_batch_metadata(saveDir, sequenceModel, pms, description, rep)
%SAVE_BATCH_METADATA Save reproducibility metadata once per batch folder.

metadataFile = fullfile(saveDir, 'sequenceModel.mat');

if isfile(metadataFile)
    return;
end

batchInfo = struct();
batchInfo.description = description;
batchInfo.rep = rep;
batchInfo.savedAt = char(datetime('now', 'Format', 'yyyyMMddHHmmss'));

save(metadataFile, 'sequenceModel', 'pms', 'batchInfo', '-v7.3');
end
