classdef prtRv
    % prtRv    Base class for all prt random variables
    %
    % This is an abstract class from which all prt random variables
    % inherit. It can not be instantiated. prtRv contains the following 
    % properties:
    %
    %   name           - Name of random variable
    %   UserData       - Structure for holding additional related to the
    %                    random variable
    %
    %   nDimensions    - Number of dimensions of the vector space
    %       represented by the random variable.
    %
    % The prtRv class has the following methods
    %
    %   plotPdf - Plot the pdf of the random variable
    %   plotCdf - Plot the cdf of the random variable
    %
    % The prtRv class has the following methods which should be overloaded
    % to provide functionality.  These functions are not abstract, because
    % some sub-classes of prtRv may not be able to implement some subset of
    % these.
    %   pdf - Output the pdf of the random variable evaluated at the points
    %       specified
    %
    %   logPdf - Output the log-pdf of the random variable evaluated at the
    %       points specified (for many distributions, this can be calculated
    %       more easily than simply log(pdf(R,X))
    %
    %   cdf - Output the cdf of the random variable evaluated at the
    %   points specified
    %
    %   draw - Draw samples from the random variable
    %
    %   mle - Perform maximum likelihood estimation using the specified
    %      data
    %
    %   See also: prtRvMvn, prtRvGmm, prtRvMultinomial
    
    properties
        name        % The name displayed
        UserData    % UserData
    end
    properties (Abstract = true, Hidden = true, Dependent = true)
        nDimensions % The number of dimensions
    end
    methods (Abstract, Hidden=true)
        bool = isValid(R)
    end
    methods
        % These functions are default "error" functions incase a
        % subclass has not specified these standard methods.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function vals = pdf(R,X) %#ok
            missingMethodError(R,'pdf');
        end

        function vals = logPdf(R,X) %#ok
            vals = log(R.pdf(X));
        end
        
        function vals = cdf(R,X) %#ok
            missingMethodError(R,'cdf');
        end
        
        function vals = draw(R,N) %#ok
            missingMethodError(R,'draw');
        end

        function vals = mle(R,X) %#ok
            % Maximum likelihood estimate
            missingMethodError(R,'mle');
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % These functions are default plotting functions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function varargout = plotPdf(R,varargin)
            varargout = {};
            if R.isPlottable
                
                if nargin > 1 % Calculate appropriate limits from covariance
                    plotLims = varargin{1};
                else
                    plotLims = plotLimits(R);
                end
                
                UserOptions = prtUserOptions;
                
                [linGrid,gridSize] = prtPlotUtilGenerateGrid(plotLims(1:2:end), plotLims(2:2:end), UserOptions.RvPlotOptions.nSamplesPerDim);
                
                imageHandle = prtPlotUtilPlotGriddedEvaledFunction(R.pdf(linGrid), linGrid, gridSize, UserOptions.RvPlotOptions.colorMapFunction(UserOptions.RvPlotOptions.nColorMapSamples));
                
                if nargout
                    varargout = {imageHandle};
                end
            else
                if R.isValid
                    error('prt:prtRv:plot','This RV object cannont be plotted because it has too many dimensions for plotting.')
                else
                    error('prt:prtRv:plot','This RV object cannot be plotted because it is not yet valid.');
                end
            end
        end
        
        function varargout = plotCdf(R,varargin)
            varargout = {};
            if R.isPlottable
                
                if nargin > 1 % Calculate appropriate limits from covariance
                    plotLims = varargin{1};
                else
                    plotLims = plotLimits(R);
                end
                
                UserOptions = prtUserOptions;
                [linGrid,gridSize] = prtPlotUtilGenerateGrid(plotLims(1:2:end), plotLims(2:2:end), UserOptions.RvPlotOptions.nSamplesPerDim);
                
                imageHandle = prtPlotUtilPlotGriddedEvaledFunction(R.cdf(linGrid), linGrid, gridSize, UserOptions.RvPlotOptions.colorMapFunction(UserOptions.RvPlotOptions.nColorMapSamples));
                
                if nargout
                    varargout = {imageHandle};
                end
            else
                if R.isValid
                    error('prt:prtRv:plot','This RV object cannont be plotted because it has too many dimensions for plotting.')
                else
                    error('prt:prtRv:plot','This RV object cannot be plotted because it is not yet valid.');
                end
            end
        end
    end
    
    methods (Hidden = true)
        % As a default we just use the monte carlo limits.
        % If a sub-class implements plotLimits ezPdfPlot or ezCdfPlot
        % should use that.
        function limits = plotLimits(R)
            limits = monteCarloPlotLimits(R);
        end
        function vals = weightedMle(R,X,weights) %#ok
            % Maximum likelihood estimate using membership weighted samples
            % This is necessary for mixtures and other hierarchical models
            missingMethodError(R,'weightedMle');
        end
        
        function initMembershipMat = initializeMixtureMembership(Rs,X,weights) %#ok
            % Initialize a mixture assumes all Rs are the same.
            % This is necessary for mixtures and other hierarchical models
            missingMethodError(R,'initializeMixtureMembership');
        end        
        
        function val = isPlottable(R)
            val = ~isempty(R.nDimensions) && R.nDimensions < 4 && R.isValid;
        end
    end
    
    methods (Access = 'private', Hidden = true)
        function missingMethodError(R,methodName)
            error('The method %s is not defined for this prtRv object',methodName);
        end
    end
    methods (Access = 'protected', Hidden = true)
        function R = constructorInputParse(R,varargin)
            
            nIn = length(varargin);

            % Quick Exit for the zero input constructor
            if nIn == 0
                return
            elseif mod(nIn,2)
                error('prt:prtRv:constructorInputParse','Inputs must be supplied by as string/value pairs');
            end
            
            R = prtUtilAssignStringValuePairs(R,varargin{:});

        end
        
        
        function val = monteCarloCovariance(R,nSamples)
            % Calculates the sample covariance of drawn data
            if nargin < 2 || isempty(nSamples)
                nSamples = 1e3;
            end
            val = cov(draw(R,nSamples));
        end

        function val = monteCarloMean(R,nSamples)
            % Calculates the sample mean of drawn data
            if nargin < 2 || isempty(nSamples)
                nSamples = 1e3;
            end
            val = mean(draw(R,nSamples));
        end
        
        function limits = monteCarloPlotLimits(R,nStds,nSamples)
            % Calculate plotting limits
            if nargin < 2 || isempty(nStds)
                nStds = 2;
            end
            if nargin < 3 || isempty(nSamples)
                nSamples = []; % Let the defaults from monteCarloMean and 
                               % monteCarloCovariance decide.
            end
                    
            mu = monteCarloMean(R,nSamples);
            C = monteCarloCovariance(R,nSamples);
            
            minX = min(mu, [], 1)' - nStds*sqrt(diag(C));
            maxX = max(mu, [], 1)' + nStds*sqrt(diag(C));
            
            limits = zeros(1,2*length(minX));
            limits(1:2:end) = minX;
            limits(2:2:end) = maxX;
        end
    end
end

