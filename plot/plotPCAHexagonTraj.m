function   plotPCAHexagonTraj(params)
% function plotPCAHexagonTraj(params)

nVert       =params.nVert;
startPoint  =params.startPoint;
splitPoint  =params.splitPoint;
nSamples    =params.nSamples;
openFrac    =params.openFrac;
lineColor   =params.lineColor;
vx          =params.vx;
vy          =params.vy;
vz          =params.vz;
widenFactor =params.widenFactor;
zsign       =rand(nVert,1)-0.5>0;
try
    nEnd    =params.Extend;
catch
    nEnd    =-1;
end

for k = 1:nVert
    P0 = startPoint;
    Pf = splitPoint;
    P2 = [vx(k) vy(k) vz(k)];

    t       = linspace(0,max(vx),nSamples);
    % nFlat   = max(2, round(openFrac * nSamples));  % samples in flat part
    nFlat   = find(t<splitPoint(1), 1, 'last' );   % samples in flat part


    x = zeros(size(t));
    y = zeros(size(t));
    z = zeros(size(t));

    % -------- flat common segment --------
    x(1:nFlat) = linspace(P0(1), Pf(1), nFlat);
    y(1:nFlat) = 0;
    z(1:nFlat) = 0;

    % -------- curved diverging part (quadratic Bézier) --------
    nCurv = nSamples - nFlat;
    if nCurv > 0
        tau = linspace(0,1,nCurv);

        % lateral offset for each branch
        baseYOffset = 0.5 * (k - (nVert+1)/2);  % spread across Y
        baseZOffset = zsign(k)*0.7;             % amount in Z
        P1 = Pf + widenFactor * [0 baseYOffset baseZOffset];

        B0 = (1-tau).^2;
        B1 = zsign(k)*2*(1-tau).*tau;
        B2 = tau.^2;

        x(nFlat+1:end) = B0*Pf(1) + B1*P1(1) + B2*P2(1);
        y(nFlat+1:end) = B0*Pf(2) + B1*P1(2) + B2*P2(2);
        z(nFlat+1:end) = B0*Pf(3) + B1*P1(3) + B2*P2(3);
    end
    % z = zsign(k)*z; 
    x = sort(x);%smooth(x,100); % monotonic;
    
    if nEnd
    % nEnd = 50;
        xend = linspace(t(end), t(end)+2, nEnd);
        yend = zeros(size(xend));
        splw = round(nEnd/4);
        yend(1:splw)=linspace(y(end), 0, splw);
        zend = zeros(size(xend));
        zend(1:splw)=linspace(z(end), 0, splw);
    end
    y = smooth(y,100);
    z = smooth(z,100);
    if nEnd
        x = [x,xend];
        y = [y;yend'];
        z = [z;zend'];
    
        y(nSamples+1:end)=smooth(y(nSamples+1:end),100);
        z(nSamples+1:end)=smooth(z(nSamples+1:end),100);
    end
    start = params.start;
    plot3(x(start:end),y(start:end),z(start:end),'-','LineWidth',6,'Color',lineColor);
end

% axis off;
% view(35,25);
%camproj('perspective');