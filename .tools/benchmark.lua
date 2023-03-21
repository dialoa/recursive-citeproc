--- benchmark.lua
--- produce a benchmark document with 100 recursive citations

BASE = [[@article{Smith2001,
title = "Thoughts",
author = "Al Smith",
year = 2001,
journal = "Varia",
volume = 1,
pages = "1--15",
}

@article{Smith2003,
title = "More Thoughts",
author = "Al Smith",
year = 2003,
journal = "Varia",
volume = 12,
pages = "35--55",
}

@article{Smith2005,
title = "Afterthoughts",
author = "Al Smith",
year = 2005,
journal = "Varia",
volume = 15,
pages = "25--33",
}
]]

ENTRY = [[@book{DoeYEAR,
	title = "A long journey",
	author = "Jane E. Doe",
	year = YEAR,
	note = "Reprint of~\citet{DoePREVIOUS}",
}
]]

LASTENTRY = [[@book{DoeYEAR,
    title = "A long journey",
    author = "Jane E. Doe",
    year = YEAR,
}
]]

result = ''
first, last = 2020, 1920
for i = first, last, -1 do
    if i > last then
        result = result .. ENTRY:gsub('YEAR', i):gsub('PREVIOUS', i-1)
    else
        result = result .. LASTENTRY:gsub('YEAR', i)
    end
end

print(result)
