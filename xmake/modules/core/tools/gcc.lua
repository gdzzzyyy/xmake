--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        gcc.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")
import("detect.tools.find_ccache")

-- init it
function init(self)

    -- init mxflags
    _g.mxflags = {  "-fmessage-length=0"
                ,   "-pipe"
                ,   "-fpascal-strings"
                ,   "-DIBOutlet=__attribute__((iboutlet))"
                ,   "-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))"
                ,   "-DIBAction=void)__attribute__((ibaction)"}

    -- init shflags
    _g.shflags = { "-shared", "-fPIC" }

    -- init cxflags for the kind: shared
    _g.shared          = {}
    _g.shared.cxflags  = {"-fPIC"}

    -- suppress warning for clang (gcc -> clang on macosx) 
    if self:has_flags("-Qunused-arguments") then
        _g.cxflags = {"-Qunused-arguments"}
        _g.mxflags = {"-Qunused-arguments"}
        _g.asflags = {"-Qunused-arguments"}
    end

    -- init flags map
    _g.mapflags = 
    {
        -- warnings
        ["-W1"] = "-Wall"
    ,   ["-W2"] = "-Wall"
    ,   ["-W3"] = "-Wall"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-S"
    }

    -- init buildmodes
    _g.buildmodes = 
    {
        ["object:sources"] = false
    }
end

-- get the property
function get(self, name)

    -- get it
    return _g[name]
end

-- make the strip flag
function nf_strip(self, level)

    -- the maps
    local maps = 
    {   
        debug = "-S"
    ,   all   = "-s"
    }

    -- make it
    return maps[level]
end

-- make the symbol flag
function nf_symbol(self, level)

    -- the maps
    local maps = 
    {   
        debug  = "-g"
    ,   hidden = "-fvisibility=hidden"
    }

    -- make it
    return maps[level] 
end

-- make the warning flag
function nf_warning(self, level)

    -- the maps
    local maps = 
    {   
        none  = "-w"
    ,   less  = "-W1"
    ,   more  = "-W3"
    ,   all   = "-Wall"
    ,   error = "-Werror"
    }

    -- make it
    return maps[level]
end

-- make the optimize flag
function nf_optimize(self, level)

    -- the maps
    local maps = 
    {   
        none       = "-O0"
    ,   fast       = "-O1"
    ,   faster     = "-O2"
    ,   fastest    = "-O3"
    ,   smallest   = "-Os"
    ,   aggressive = "-Ofast"
    }

    -- make it
    return maps[level] 
end

-- make the vector extension flag
function nf_vectorext(self, extension)

    -- the maps
    local maps = 
    {   
        mmx   = "-mmmx"
    ,   sse   = "-msse"
    ,   sse2  = "-msse2"
    ,   sse3  = "-msse3"
    ,   ssse3 = "-mssse3"
    ,   avx   = "-mavx"
    ,   avx2  = "-mavx2"
    ,   neon  = "-mfpu=neon"
    }

    -- make it
    return maps[extension] 
end

-- make the language flag
function nf_language(self, stdname)

    -- the stdc maps
    local cmaps = 
    {
        -- stdc
        ansi        = "-ansi"
    ,   c89         = "-std=c89"
    ,   gnu89       = "-std=gnu89"
    ,   c99         = "-std=c99"
    ,   gnu99       = "-std=gnu99"
    ,   c11         = "-std=c11"
    ,   gnu11       = "-std=gnu11"
    }

    -- the stdc++ maps
    local cxxmaps = 
    {
        cxx98       = "-std=c++98"
    ,   gnuxx98     = "-std=gnu++98"
    ,   cxx11       = "-std=c++11"
    ,   gnuxx11     = "-std=gnu++11"
    ,   cxx14       = "-std=c++14"
    ,   gnuxx14     = "-std=gnu++14"
    ,   cxx17       = "-std=c++17"
    ,   gnuxx17     = "-std=gnu++17"
    ,   cxx1z       = "-std=c++1z"
    ,   gnuxx1z     = "-std=gnu++1z"
    }

    -- select maps
    local maps = cmaps
    if self:kind() == "cxx" or self:kind() == "mxx" then
        maps = cxxmaps
    elseif self:kind() == "sc" then
        maps = {}
    end

    -- make it
    return maps[stdname]
end

-- make the define flag
function nf_define(self, macro)
    return "-D" .. macro
end

-- make the undefine flag
function nf_undefine(self, macro)
    return "-U" .. macro
end

-- make the includedir flag
function nf_includedir(self, dir)
    return "-I" .. os.args(dir)
end

-- make the link flag
function nf_link(self, lib)
    return "-l" .. lib
end

-- make the linkdir flag
function nf_linkdir(self, dir)
    return "-L" .. os.args(dir)
end

-- make the rpathdir flag
function nf_rpathdir(self, dir)
    if self:has_flags("-Wl,-rpath=" .. dir) then
        return "-Wl,-rpath=" .. os.args(dir:gsub("@[%w_]+", function (name)
            local maps = {["@loader_path"] = "$ORIGIN", ["@executable_path"] = "$ORIGIN"}
            return maps[name]
        end))
    elseif self:has_flags("-Xlinker -rpath -Xlinker " .. dir) then
        return "-Xlinker -rpath -Xlinker " .. os.args(dir:gsub("%$ORIGIN", "@loader_path"))
    end
end

-- make the framework flag
function nf_framework(self, framework)
    return "-framework " .. framework
end

-- make the frameworkdir flag
function nf_frameworkdir(self, frameworkdir)
    return "-F " .. os.args(frameworkdir)
end

-- make the c precompiled header flag
function nf_pcheader(self, pcheaderfile, target)
    if self:kind() == "cc" then
        if self:name() == "clang" then
            return "-include " .. os.args(pcheaderfile) .. " -include-pch " .. os.args(target:pcoutputfile("c"))
        else
            return "-include " .. os.args(pcheaderfile)
        end
    end
end

-- make the c++ precompiled header flag
function nf_pcxxheader(self, pcheaderfile, target)
    if self:kind() == "cxx" then
        if self:name() == "clang" then
            return "-include " .. os.args(pcheaderfile) .. " -include-pch " .. os.args(target:pcoutputfile("cxx"))
        else
            return "-include " .. os.args(pcheaderfile)
        end
    end
end

-- make the link arguments list
function linkargv(self, objectfiles, targetkind, targetfile, flags)

    -- add rpath for dylib (macho), .e.g -install_name @rpath/file.dylib
    local flags_rpath = nil
    if targetkind == "shared" and targetfile:endswith(".dylib") then
        flags_rpath = {"-install_name", "@rpath/" .. path.filename(targetfile)}
    end
    return self:program(), table.join("-o", targetfile, objectfiles, flags, flags_rpath)
end

-- link the target file
function link(self, objectfiles, targetkind, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.runv(linkargv(self, objectfiles, targetkind, targetfile, flags))
end

-- get include deps
function _include_deps(self, sourcefile, flags)

    -- the temporary file
    local tmpfile = os.tmpfile()

    -- uses pchflags for precompiled header
    if _g._PCHFLAGS then
        local key = sourcefile .. tostring(flags)
        local pchflags = _g._PCHFLAGS[key] 
        if pchflags then
            flags = pchflags
        end
    end

    -- generate it
    os.runv(self:program(), table.join("-c", "-E", "-MM", flags or {}, "-o", tmpfile, sourcefile))

    -- translate it
    results = {}
    local deps = io.readfile(tmpfile)
    for includefile in string.gmatch(deps, "%s+([%w/%.%-%+_%$%.]+)") do

        -- save it if belong to the project
        if not path.is_absolute(includefile) then
            table.insert(results, includefile)
        end
    end

    -- remove the temporary file
    os.rm(tmpfile)

    -- ok?
    return results
end

-- make the complie arguments list for the precompiled header
function _compargv1_pch(self, pcheaderfile, pcoutputfile, flags)

    -- init key and cache
    local key = pcheaderfile .. tostring(flags)
    _g._PCHFLAGS = _g._PCHFLAGS or {}

    -- remove "-include xxx.h" and "-include-pch xxx.pch"
    local pchflags = {}
    local include = false
    for _, flag in ipairs(flags) do
        if not flag:find("-include", 1, true) then
            if not include then
                table.insert(pchflags, flag)
            end
            include = false
        else
            include = true
        end
    end

    -- compile header.h as c++?
    if self:kind() == "cxx" then
        table.insert(pchflags, "-x")
        table.insert(pchflags, "c++-header")
    end

    -- save pchflags to cache
    _g._PCHFLAGS[key] = pchflags

    -- make complie arguments list
    return self:program(), table.join("-c", pchflags, "-o", pcoutputfile, pcheaderfile)
end

-- make the complie arguments list
function _compargv1(self, sourcefile, objectfile, flags)

    -- precompiled header?
    local extension = path.extension(sourcefile)
    if (extension:startswith(".h") or extension == ".inl") then
        return _compargv1_pch(self, sourcefile, objectfile, flags)
    end

    -- get ccache
    local ccache = nil
    if config.get("ccache") then
        ccache = find_ccache()
    end

    -- make argv
    local argv = table.join("-c", flags, "-o", objectfile, sourcefile)

    -- uses cache?
    local program = self:program()
    if ccache then
            
        -- parse the filename and arguments, .e.g "xcrun -sdk macosx clang"
        if not os.isexec(program) then
            argv = table.join(program:split("%s"), argv)
        else 
            table.insert(argv, 1, program)
        end
        return ccache, argv
    end

    -- no cache
    return program, argv
end

-- complie the source file
function _compile1(self, sourcefile, objectfile, depinfo, flags)

    -- ensure the object directory
    os.mkdir(path.directory(objectfile))

    -- compile it
    try
    {
        function ()
            local outdata, errdata = os.iorunv(_compargv1(self, sourcefile, objectfile, flags))
            return (outdata or "") .. (errdata or "")
        end,
        catch
        {
            function (errors)

                -- try removing the old object file for forcing to rebuild this source file
                os.tryrm(objectfile)

                -- find the start line of error
                local lines = errors:split("\n")
                local start = 0
                for index, line in ipairs(lines) do
                    if line:find("error:", 1, true) or line:find("错误：", 1, true) then
                        start = index
                        break
                    end
                end

                -- get 16 lines of errors
                if start > 0 or not option.get("verbose") then
                    if start == 0 then start = 1 end
                    errors = table.concat(table.slice(lines, start, start + ifelse(#lines - start > 16, 16, #lines - start)), "\n")
                end

                -- raise compiling errors
                os.raise(errors)
            end
        },
        finally
        {
            function (ok, warnings)

                -- print some warnings
                if warnings and #warnings > 0 and (option.get("verbose") or option.get("warning")) then
                    cprint("${yellow}%s", table.concat(table.slice(warnings:split('\n'), 1, 8), '\n'))
                end
            end
        }
    }

    -- generate the dependent includes
    if depinfo and self:kind() ~= "as" then
        depinfo.includes = _include_deps(self, sourcefile, flags)
    end
end

-- make the complie arguments list
function compargv(self, sourcefiles, objectfile, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    return _compargv1(self, sourcefiles, objectfile, flags)
end

-- complie the source file
function compile(self, sourcefiles, objectfile, depinfo, flags)

    -- only support single source file now
    assert(type(sourcefiles) ~= "table", "'object:sources' not support!")

    -- for only single source file
    _compile1(self, sourcefiles, objectfile, depinfo, flags)
end

