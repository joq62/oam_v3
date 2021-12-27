%% This is the application resource file (.app file) for the 'base'
%% application.
{application, oam,
[{description, "Oam application and cluster" },
{vsn, "0.1.0" },
{modules, 
	  [oam,oam_sup,oam_app,oam_server]},
{registered,[oam]},
{applications, [kernel,stdlib]},
{mod, {oam_app,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/oam.git"}
]}.
