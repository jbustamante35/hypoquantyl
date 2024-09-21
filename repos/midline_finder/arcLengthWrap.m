function [xi] = arcLengthWrap(x,MX)
    xi = rem(x,MX);
    if xi < 0;xi = xi + MX;end
end