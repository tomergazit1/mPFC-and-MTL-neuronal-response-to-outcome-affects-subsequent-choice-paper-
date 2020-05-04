function binned_vec = bin_spikes(vec, bin_size)
% this function arranges spikes times in bins
if (length(vec)/bin_size ~= round(length(vec)/bin_size))
    number_of_bins = floor(length(vec)/bin_size);
    tmp = sprintf('Warning: using %d out of %d points to match bin_size %d', number_of_bins*bin_size, length(vec), bin_size);
    disp(tmp);
    vec = vec(1:number_of_bins*bin_size);
end;
binned_vec = sum(reshape(vec, bin_size, round(length(vec)/bin_size)));