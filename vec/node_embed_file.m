function [U,L_hat,ccr,nmi] = node_embed_file(G,L,k,doNBT,len)
% Implements the node embeddings 'vec' algorithm of Ding et al. including a
% non-backtracking random walks option. This version works with file I/O
% and the use of the compiled "word2vec" code of Mikolov et al. 
% Inputs:
% G: graph in adjacency matrix form. Directed graphs should work; weighted
%    graphs will be left for a future version.
% L: ground truth of the embedding.
% doNBT: whether or not to do non-backtracking random walks on the graph.
% len: the length of the random walk.
% other parameters can be set manually for now; it's more annoying than
% helpful to have 10 different arguments to the program.
% Outputs:
% U: the embedding produced
% L_hat: the labels identified by the algorithm.
% ccr: the correct classification rate.
% nmi: the normalized mutual information of the output.
% 
% Brian Rappaport, 7/24/17
% Updated 4/19/18

% set vars
if size(L,2) ~= 1, L = L'; end % ensure L is a column vector
%k = max(L); % number of communities
rw_reps = 20; % number of random walks per data point
dim = 12; % embedded dimension
winsize = 5; % window size
read_fp = 'sentences.txt';
write_fp = 'embeddings.txt';

% write random walks to file
nodes2file(G,read_fp,rw_reps,len,doNBT);
% run word2vec with external C code
command = ['./word2vec -train ' read_fp ' -output ' write_fp ...
          ' -size ' num2str(dim) ' -window ' num2str(winsize) ...
          ' -sample 1e-4 -debug 0'];
system(command);
% get embeddings from word2vec
[U,labels] = file2embs(write_fp);
L = L(labels);
% run kmeans
L_hat = kmeans(U,k);
L_hat = get_true_emb(L_hat,L);
ccr = sum(L_hat == L)*100/numel(L);
nmi = get_nmi(L_hat, L);
end

function [U,labels] = file2embs(filename)
% Reads a file from word2vec and returns it as an array in memory.
U = dlmread(filename,' ',2,0);
labels = U(:,1);
U = U(:,2:end-1);
end

function nodes2file(G,filename,rw_reps,len,doNBT)
% Runs random walks on G and writes to a file. Note that all walks must be
% exactly len nodes long or this will have fairly catastrophic off-by-one
% errors.
n = size(G,1);
rw = zeros(len,rw_reps,n);
for i = 1:n
    if isempty(find(G(i,:),1))
        continue
    end
    for j = 1:rw_reps
        rw(:,j,i) = random_walk(i,len,G,doNBT);
    end
end
rw(rw==0) = [];
fmtstr = repmat('%d ',1,len);
fmtstr = [fmtstr(1:end-1) '\n'];
fp = fopen(filename,'wb');
fprintf(fp,fmtstr,rw);
fclose(fp);
end
