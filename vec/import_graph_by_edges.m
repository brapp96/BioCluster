function [G,L] = import_graph_by_edges(filename)
fp = fopen(filename,'rb');
indi = [];
indj = [];
N = 0;
line = '#';
while line(1) ~= '['
    if line(1) ~= '#'
        N = N+1;
        I = eval(['[' line ']']);
        indi(end+1:end+numel(I)-1) = I(1)*ones(1,numel(I)-1);
        indj(end+1:end+numel(I)-1) = I(2:end);
    end
    line = fgets(fp);
end
G = sparse(indi+1,indj+1,1,N,N);
G = G + G';
L = eval(line)+1;
fclose(fp);
end
