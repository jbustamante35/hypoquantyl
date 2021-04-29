function [para] = createDomain(para)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create domains - general -
    % creates either 'disks' or 'lines' as domains 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INPUT:     
    %           para.type   := the domain type
    %           para.value  := [extent num_points]
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OUTPUT:   
    %           para.D      := attached domain to the para
    %           para.sz     := attached size to para
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch para.type
        case 'disk'
            % special case - 2D for now
            % generate box
            [para] = genBox(para);
            % bend 
            para.d = [para.d(:,1).*cos(para.d(:,2)) para.d(:,1).*sin(para.d(:,2)) ones(prod(para.sz),1)]';
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % rep
            RHO = para.value{1}(2);
            TH = linspace(para.value{2}(1),para.value{2}(2),200)';
            para.rep = [RHO.*cos(TH) RHO.*sin(TH) ones(size(TH))]';
            
        case 'box'        
            para = genBox(para);
            para.d = [(para.d');ones(1,size(para.d,1))];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % rep
            c1 = [para.value{1}(1) para.value{2}(1) 1];
            c2 = [para.value{1}(1) para.value{2}(2) 1];
            c3 = [para.value{1}(2) para.value{2}(2) 1];
            c4 = [para.value{1}(2) para.value{2}(1) 1];            
            para.rep = [c1;c2;c3;c4;c1]';
            %para.rep(1:2,:) = flipud(para.rep(1:2,:));
    end
end

function [para] = genBox(para)
    % create basis vecs
    % para.value{e} = [min max numPoints];
    for e = 1:numel(para.value)
        para.bv(e).v = linspace(para.value{e}(1),para.value{e}(2),para.value{e}(3));
    end
    % generate box-top
    para = myGrid(para);
end

function [para] = genRep(para)
    % create basis vecs
    % para.value{e} = [min max numPoints];
    
end

%{  
    clear para
    para.type = 'disk';
    para.value{1} = [0 28 28];
    para.value{2} = [0 28 28];
    para = createDomain(para);
%}
    
