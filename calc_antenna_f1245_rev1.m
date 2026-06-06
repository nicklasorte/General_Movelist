function [G_dBi]=calc_antenna_f1245_rev1(app,phi_deg, Gmax_dBi, D_m, FreqMHz)
%F1245_3_GAIN  ITU-R F.1245-3 antenna gain model (1-70 GHz)
%
% Implements:
%   Section 2.1.1  -> D/lambda > 100
%   Section 2.2.1  -> D/lambda <= 100
%
% Inputs:
%   phi_deg    - Off-axis angle(s) in degrees
%   Gmax_dBi   - Maximum antenna gain (dBi)
%   D_m        - Antenna diameter (meters)
%   f_GHz      - Frequency (GHz)
%
% Output:
%   G_dBi      - Antenna gain (dBi)
%
% Reference:
%   ITU-R F.1245-3 Sections 2.1.1 and 2.2.1
%
% Notes:
%   - phi can be scalar/vector/matrix
%   - phi=0 returns Gmax
%   - log means log10

    c = 299792458;                 % Speed of light (m/s)
    f_GHz=FreqMHz/1000;
    lambda_m = c / (f_GHz * 1e9);  % Wavelength (m)

    D_over_lambda = D_m / lambda_m;

    if f_GHz < 1 || f_GHz > 70
        error('This implementation applies only for 1-70 GHz.');
    end

    phi = abs(phi_deg);
    phi(phi > 180) = 180;

    G_dBi = zeros(size(phi));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SECTION 2.1.1
    % D/lambda > 100
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if D_over_lambda > 100

        G1 = 2 + 15 * log10(D_over_lambda);

        phi_m = (20 / D_over_lambda) * sqrt(Gmax_dBi - G1);

        phi_r = 12.02 * D_over_lambda^(-0.6);

        phi_break = max(phi_m, phi_r);

        idx0 = (phi == 0);
        idx1 = (phi > 0) & (phi < phi_m);
        idx2 = (phi >= phi_m) & (phi < phi_break);
        idx3 = (phi >= phi_break) & (phi < 48);
        idx4 = (phi >= 48) & (phi <= 180);

        % Main beam
        G_dBi(idx0) = Gmax_dBi;

        G_dBi(idx1) = Gmax_dBi ...
            - 2.5e-3 * (D_over_lambda .* phi(idx1)).^2;

        % First sidelobe plateau
        G_dBi(idx2) = G1;

        % Log sidelobe region
        G_dBi(idx3) = 29 - 25 * log10(phi(idx3));

        % Backlobe region
        G_dBi(idx4) = -13;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SECTION 2.2.1
    % D/lambda <= 100
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else

        phi_m = ...
            (20 / D_over_lambda) * sqrt( ...
            Gmax_dBi - (39 - 5 * log10(D_over_lambda)) );

        idx0 = (phi == 0);
        idx1 = (phi > 0) & (phi < phi_m);
        idx2 = (phi >= phi_m) & (phi < 48);
        idx3 = (phi >= 48) & (phi <= 180);

        % Main beam
        G_dBi(idx0) = Gmax_dBi;

        G_dBi(idx1) = Gmax_dBi ...
            - 2.5e-3 * (D_over_lambda .* phi(idx1)).^2;

        % Log sidelobe region
        G_dBi(idx2) = ...
            39 ...
            - 5 * log10(D_over_lambda) ...
            - 25 * log10(phi(idx2));

        % Backlobe region
        G_dBi(idx3) = ...
            -3 - 5 * log10(D_over_lambda);

    end
end