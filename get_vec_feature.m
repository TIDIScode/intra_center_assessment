function vec_feature = get_vec_feature(feature)

[Nx,Ny,Nz] = size(feature);
vec_feature = zeros(Nz,Nx*Ny);

    parfor k = 1:Nz
        Z = feature(:,:,k);
        vec_feature(k,:) = Z(:)';
    end
end
