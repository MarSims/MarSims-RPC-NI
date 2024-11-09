function [indexKNN,lammda,Rho,rep,Crep] = Rep_Point_Searching(data)
%============================================================
% Aim:
% Determing core representative points
% ----------------------------------------------------------
% Input:
% data: the dataset
% ----------------------------------------------------------
% Output:
% indexKNN: k nearest neighbors
% lammda: value of the natural eigenvalue
% Rho: neighborhood density
% rep: representative points
% Crep: core reppresentative points
%=============================================================

%% Step 1.1: detemine the natural neighbors
[N,~]=size(data);
kdtree = createns(data,'NSMethod','kdtree','Distance','euclidean');
maxK = 20*ceil(log2(N)); 
[index,knnD] = knnsearch(kdtree,data(:,:),'k',maxK);

% disp('Search natural neighbors...');
r=1; flag=0;
nb=zeros(1,N);  
count=0;        
count1=0;       

while flag==0
    for i=1:N
        K=index(i,r+1);
        nb(K)=nb(K)+1;
    end
    r=r+1;
    [~,count2]=size(find(nb==0));
    if count1==count2
        count=count+1;
    else
        count=1;
    end
    if count2==0 || (r>2 && count>=2) 
        flag=1;
    end
    count1=count2;
end

lammda = r-1;             % lammda
K = max(nb);              % maximum number of natural neighbors
% disp('lammda');disp(lammda); disp('max_nb');disp(K);

%% Step 1.2: compute local centrality
indexknn = index(:,2:K+1);
knnD = knnD(:,2:K+1);

rho = K./sum(knnD,2);                    % k-density
weighted_rho_sum = sum((1 ./ (1 + knnD)) .* rho(indexknn), 2);
Rho = rho + (1 / K) * weighted_rho_sum;  % neighborhood density

msdata = data;
for i = 1:N
    msdata(i,:) = sum(msdata(indexknn(i,:),:))/K;  
end
ms_vec = msdata - data;                  % mean-shift vector

%========= Plot the mean-shift vector ========= 
% figure
% scatter(data(:,1), data(:,2), 'filled');
% hold on;
% quiver(data(:,1), data(:,2), ms_vec(:,1), ms_vec(:,2), 0, 'Color', [0.5, 0.5, 0.5]);
% hold on
% scatter(msdata(:,1), msdata(:,2), 'filled');
%==============================================

Ita = zeros(N, 1);  % project vector
ms_norm = vecnorm(ms_vec, 2, 2);
for i = 1:N
    e_vec = data(indexknn(i,:), :) - data(i,:);   % Euclidean vector for i
    e_norm = vecnorm(e_vec, 2, 2);                % norm of e_vec
    ms_proj = (sum(ms_vec(indexknn(i,:),:) .* e_vec, 2) ./ (e_norm .^ 2)) .* e_vec;  % project vector

    proj_norm = vecnorm (ms_proj, 2, 2);  
    sim = 1 ./ (1 + abs(proj_norm - e_norm) ./ ms_norm(indexknn(i,:)));  % compute similarity between vectors

    Ita(i) = sum(sim) / K;
end
LC = sqrt(Rho .* Ita);  % Local Centrality

%% Step 1.3: determine representative points
% disp('determine Reps...')
indexKNN = index(:,1:lammda+1);
[~,max_ind] = max(LC(indexKNN),[],2); 
rep =zeros(N,1); % Pre-allocate the space for the parent node vector. 
for i=1:N
    rep(i) = indexKNN(i,max_ind(i)); % pr(i): parent node of node i;
end
Crep = find(rep == (1:N)');

%================ Plot each point and its reps ================
% figure;
% plot(data(:,1),data(:,2),'ko','MarkerSize',5,'MarkerFaceColor','k');
% hold on;
% for i=1:N
%     plot([data(i,1),data(rep(i),1)],[data(i,2),data(rep(i),2)],'linewidth',1.5,'color','k','LineStyle',':');
%     hold on;
% end
% plot(data(rep,1),data(rep,2),'rs','MarkerSize',6,'MarkerFaceColor','w');
%===============================================================

visited=zeros(N,1);  % updata reps
for i = 1:N
    if rep(i) ~= i
        parent = i;
        round = 1;
        visited(round) = i;
        while rep(parent) ~= parent
            parent = rep(parent);
            round = round+1;
            visited(round) = parent;
        end
        rep(visited(1:round)) = parent;
    end
end

%=========== Plot each point and its core reps =============
% figure;
% plot(data(:,1),data(:,2),'ko','MarkerSize',5,'MarkerFaceColor','k');
% hold on;
% for i=1:N
%     plot([data(i,1),data(rep(i),1)],[data(i,2),data(rep(i),2)],'linewidth',1.5,'color','k','LineStyle',':');
%     hold on;
% end
% plot(data(rep,1),data(rep,2),'ro','MarkerSize',6,'MarkerFaceColor','r');
%===========================================================

%% Step 1.4: initial clustering
% cl = zeros(N,1); % Preallocate the space for the cluster label vector; c(i): cluster label of node i;
% cl(Crep) = 1:length(Crep); % first, assign cluster labels to the root nodes;
% cl = cl(rep); % then, assign cluster labels to non-root nodes based on the root nodes they have reached

%%======== Plot the core reps and the initial clustering results ========
% figure;
% plot(data(:,1),data(:,2),'.');
% hold on;
% for i=1:N
%     plot([data(i,1),data(rep(i),1)],[data(i,2),data(rep(i),2)],':k','linewidth',1);
%     hold on;
% end
% % drawcluster2(data,cl,length(Crep)+1);
% hold on;
% plot(data(rep,1),data(rep,2),'ro','MarkerSize',8,'MarkerFaceColor','r','MarkerEdgeColor','r');
%========================================================================

end



