function out = biasCorrect_run_results(job)

% created form Antoine Lutti code:
% this function does automatic bias correction for an EPI series by
% segmenting the first image and applying the bias field to all images
% FORMAT spm_biascorrect(epi) where epi can be a path containing an EPI
% series, or a cellstr containing the EPI images in question
% Dominik R Bach & Guillaume Flandin 3.3.2010

% Disclaimer - This routine has not been fully validated or published.

% use :  spm_biascorrect(cellstr(spm_select))

sessionNumber = length(job.data);
file = {};
    for i = 1:sessionNumber

        epi = job.data{1,i};
        epi = strrep(epi,',1','');
        % get EPI images
        % -------------------------------------------------------------------------
        if ischar(epi) && exist(epi, 'dir')
            epi_all = cellstr(spm_select('FPList',epi,'^f.*\.(img|nii)$'));
            epipath = epi;
        elseif iscell(epi)
            epi_all = epi;
            [epipath foo bar] = fileparts(epi{1});
        else
            warning('Unknown input arguments'); return;
        end;


        clear matlabbatch
        matlabbatch{1}.spm.tools.preproc8.channel.vols = {epi_all{1}};
        matlabbatch{1}.spm.tools.preproc8.channel.write = [1 0];
        spm_jobman('run', matlabbatch);


        % read bias field into memory
        % -------------------------------------------------------------------------
%         bf = fullfile(epipath, spm_select('List', epipath, '^BiasField.*\.nii$'));
        bf = fullfile(epipath,spm_select('List',epipath, ['^BiasField_',foo]));
        bfv = spm_vol(bf);
        BF = double(spm_read_vols(bfv));


        % apply bias field
        % -------------------------------------------------------------------------
        for f = 1:numel(epi_all)
            fprintf('Image %d\n',f);
            % read file
            fn = [epi_all{f}];
            V = spm_vol(fn);
            Y = spm_read_vols(V);
            % apply bias field
            Y = BF.*Y;
            % save file
            [pth fnn ext] = fileparts(fn);
            nfn = fullfile(pth, ['b', fnn, ext]);
            file = [file;{nfn}];
            V.fname = nfn;
            spm_write_vol(V,Y);
        end;

    end
out.files = file;
end