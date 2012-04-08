/*
 * Copyright (c) 2006-2007 Dave Dribin
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "MameUtilApp.h"

// MAME headers
//#include "driver.h"
#include "emu.h"
#include "clifront.h"

@implementation MameUtilApp

- (void) printUsage: (FILE *) stream;
{
    ddfprintf(stream, @"Usage: %@ [OPTIONS] [<gamename|wildcard>]\n", DDCliApp);
}

- (void) printHelp;
{
    [self printUsage: stdout];
    printf("\n"
           "  -x, --listxml                 List game details\n"
           "  -l, --listfull                List driver names and descriptions\n"
           "  -s, --listsource              List source files\n"
           "  -c, --listclones              List of clones\n"
           "      --listcrc                 List of CRCs\n"
           "      --version                 Display version and exit\n"
           "  -h, --help                    Display this help and exit\n"
           "\n"
           "A utility application for MAME OS X.\n");
}

- (void) printVersion;
{
    ddprintf(@"%@ version %s\n", DDCliApp, CURRENT_MARKETING_VERSION);
}

- (void) application: (DDCliApplication *) app
    willParseOptions: (DDGetoptLongParser *) optionsParser;
{
    DDGetoptOption optionTable[] = 
    {
        // Long         Short   Argument options
        {@"listxml",    'x',    DDGetoptNoArgument},
        {@"listfull",   'l',    DDGetoptNoArgument},
        {@"listsource", 's',    DDGetoptNoArgument},
        {@"listclones", 'c',    DDGetoptNoArgument},
        {@"listcrc",    0,      DDGetoptNoArgument},

        {@"version",    0,      DDGetoptNoArgument},
        {@"help",       'h',    DDGetoptNoArgument},
        {nil,           0,      0},
    };
    [optionsParser addOptionsFromTable: optionTable];
}

- (int) application: (DDCliApplication *) app
   runWithArguments: (NSArray *) arguments;
{
    if (_help)
    {
        [self printHelp];
        return 0;
    }
    
    if (_version)
    {
        [self printVersion];
        return 0;
    }
    
    if ([arguments count] > 1)
    {
        ddfprintf(stderr, @"%@: Unexpected arguments\n", DDCliApp);
        [self printUsage: stderr];
        ddfprintf(stderr, @"Try `%@ --help' for more information.\n",
                  DDCliApp);
        return 1;
    }
    
    const char * game = "*";
    if ([arguments count] == 1)
    {
        game = [[arguments objectAtIndex: 0] UTF8String];
    }
    
    //core_options * options = mame_options_init(NULL);
    core_options * options = mame_options();
    if (_listxml)
        cli_info_listxml(options, game);
    else if (_listfull)
        cli_info_listfull(options, game);
    else if (_listsource)
        cli_info_listsource(options, game);
    else if (_listclones)
        cli_info_listclones(options, game);
    else if (_listcrc)
        cli_info_listcrc(options, game);
    
    return 0;
}


@end
