//==============================================
//  check harmony rules
// 
//  Copyright (C)2015 Jörn Eichler (heuchi) 
//
//  This plugin aims at providing the functionality of the
//  harmonyRules plugin for v1.3 created by Yvonne Cliff
//
//  This plugin is not a port of the original version,
//  but has been completely rewritten.
//
//  Results of both plugins might therefore sometimes be different.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//==============================================

import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 1.0

MuseScore {
      menuPath: "Plugins.Proof Reading.Check Harmony Rules"
      description: "Check harmony rules.\nBased on the textbook 'First Year Harmony' by William Lovelock and aiming at providing the functionality of the plugin harmonyRules by Yvonne Cliff for MuseScore v1.x"
      version: "0.1"

      // colors taken from harmonyRules plugin
      property var colorFifth: "#e21c48";
      property var colorOctave: "#ff6a07";
      property var colorLargeInt: "#7b0e7f";
      property var colorError: "#ff6a64";

      property bool processAll: false;
      property bool errorChords: false;

      MessageDialog {
            id: msgMoreNotes
            title: "Warning"
            text: "This plugin only checks the top note of each voice.\nChords are ignored."
            
            onAccepted: {
                  Qt.quit();
            }

            visible: false;
      }

      function sgn(x) {
            if (x > 0) return(1);
            else if (x == 0) return(0);
            else return(-1);
      }

      function isBetween(note1,note2,n) {
            // test if pitch of note n is between note1 and note2
            if (note1.pitch > note2.pitch) {
                  if (n.pitch < note1.pitch && n.pitch > note2.pitch)
                        return true;
            } else {
                  if (n.pitch < note2.pitch && n.pitch > note1.pitch)
                        return true;
            }
            return false;
      }            

      function markColor(note1, note2, color) {
            note1.color = color;
            note2.color = color;
      }

      function markText(note1, note2, msg, color, trck, tick) {
            markColor(note1, note2, color);
            var myText = newElement(Element.STAFF_TEXT);
            myText.text = msg;
            //myText.pos.x = 0;
            myText.pos.y = 1;
            
            var cursor = curScore.newCursor();
            cursor.rewind(0);
            cursor.track = trck;
            while (cursor.tick < tick) {
                  cursor.next();
            }
            cursor.add(myText);
      }            

      function isAugmentedInt(note1, note2) {
            var dtpc = note2.tpc - note1.tpc;
            var dpitch = note2.pitch - note1.pitch;

            // augmented intervals have same sgn for dtpc and dpitch
            if (sgn(dtpc) != sgn(dpitch))
                  return false;

            dtpc = Math.abs(dtpc);
            dpitch = Math.abs(dpitch) % 12;

            // augmented intervalls have tpc diff > 5
            if (dtpc < 6)
                  return false;
            if (dtpc == 7 && dpitch == 1) // aug. Unison / Octave
                  return true;
            if (dtpc == 9 && dpitch == 3) // aug. Second / Ninth
                  return true;
            if (dtpc == 11 && dpitch == 5) // aug. Third / ...
                  return true;
            if (dtpc == 6 && dpitch == 6) // aug. Fourth
                  return true;
            if (dtpc == 8 && dpitch == 8) // aug. Fifth
                  return true;
            if (dtpc == 10 && dpitch == 10) // aug. Sixth
                  return true;
            if (dtpc == 12 && dpitch == 0) // aug. Seventh
                  return true;
            
            // not augmented
            return false;
      }

      function checkDim47(note1, note2, track, tick) {
            var dtpc = note2.tpc - note1.tpc;
            var dpitch = note2.pitch - note1.pitch;

            // diminished intervals have opposite sgn for dtpc and dpitch
            if (sgn(dtpc) == sgn(dpitch)) {
                  return;
            }

            dtpc = Math.abs(dtpc);
            dpitch = Math.abs(dpitch) % 12;

            if (dtpc == 8 && dpitch == 4) { // dim. Fourth
                  markText(note1, note2, "dim. 4th, avoid for now",
                        colorError,track,tick);
            } else if (dtpc == 9 && dpitch == 9) { // dim. Seventh
                  markText(note1, note2, "dim. 7th, avoid for now",
                        colorError,track,tick);
            }
      }

      function checkDim5(note1, note2, note3, track, tick) {
            var dtpc = note2.tpc - note1.tpc;
            var dpitch = note2.pitch - note1.pitch;

            // diminished intervals have opposite sgn for dtpc and dpitch
            if (sgn(dtpc) == sgn(dpitch)) {
                  return;
            }

            dtpc = Math.abs(dtpc);
            dpitch = Math.abs(dpitch) % 12;

            if (dtpc == 6 && dpitch == 6) {
                  // check if note3 is inbetween
                  if (!isBetween(note1,note2,note3)) {
                        note3.color = colorError;
                        markText(note1,note2,
                        "dim. 5th should be followed by\nnote within interval",
                              colorError,track,tick);
                  }
            }
      }

      function check6NextNote(note1, note2, note3, track, tick) {
            var dtpc = note2.tpc - note1.tpc;
            var dpitch = note2.pitch - note1.pitch;
            var sameSgn = (sgn(dtpc) == sgn(dpitch));
            dtpc = Math.abs(dtpc);
            dpitch = Math.abs(dpitch) % 12;
      
            // check dim6th, min. 6th or maj. 6th
            if ((dtpc == 11 && dpitch == 7 && !sameSgn)
             || (dtpc == 4 && dpitch == 8 && !sameSgn)
             || (dtpc == 3 && dpitch == 9 && sameSgn)) {
                  // check if note3 is inbetween
                  if (!isBetween(note1,note2,note3)) {
                        note3.color = colorError;
                        markText(note1,note2,
                        "6th better avoided, but should be followed by\nnote within interval",
                              colorError,track,tick);
                  } else {
                        markText(note1,note2,
                        "6th better avoided",
                              colorError,track,tick);
                  }
            }
      }

      function check7AndLarger(note1, note2, track, tick, flag) {
            var dtpc = Math.abs(note2.tpc - note1.tpc);
            var dpitch = Math.abs(note2.pitch - note1.pitch);
            
            if (dpitch > 9 && dpitch != 12 && dtpc < 6) {
                  if (flag) {
                        markText(note1,note2,
                        "No 7ths, 9ths or larger\nnor with 1 note in between",
                        colorLargeInt,track,tick);
                  } else {
                        markText(note1, note2,
                        "No 7ths, 9ths or larger",colorLargeInt,track,tick);
                  }
            }
      }

      function isOctave(note1, note2) {
            var dtpc = Math.abs(note2.tpc - note1.tpc);
            var dpitch = Math.abs(note2.pitch - note1.pitch);
            if (dpitch == 12 && dtpc == 0)
                  return true;
            else
                  return false;
      }

      function check8(note1, note2, note3, track, tick) {
            // check if note2 and note3 form an octave
            // and note1 is not inbetween
            if (isOctave(note2,note3) && !isBetween(note2,note3,note1)) {
                  note3.color = colorError;
                  markText(note1,note2,
                        "Octave should be preceeded by note within compass",
                        colorError,track,tick);
            }
            // check if note1 and note2 form an octave
            // and note3 is not inbetween
            if (isOctave(note1,note2) && !isBetween(note1,note2,note3)) {
                  note3.color = colorError;
                  markText(note1,note2,
                        "Octave should be followed by note within compass",
                        colorError,track,tick);
            }
      }           

      onRun: {
            console.log("start")
            if (typeof curScore == 'undefined' || curScore == null) {
                  console.log("no score found");
                  Qt.quit();
            }

            // find selection
            var startStaff;
            var endStaff;
            var endTick;

            var cursor = curScore.newCursor();
            cursor.rewind(1);
            if (!cursor.segment) {
                  // no selection
                  console.log("no selection: processing whole score");
                  processAll = true;
                  startStaff = 0;
                  endStaff = curScore.nstaves;
            } else {
                  startStaff = cursor.staffIdx;
                  cursor.rewind(2);
                  endStaff = cursor.staffIdx+1;
                  endTick = cursor.tick;
                  if(endTick == 0) {
                        // selection includes end of score
                        // calculate tick from last score segment
                        endTick = curScore.lastSegment.tick + 1;
                  }
                  cursor.rewind(1);
                  console.log("Selection is: Staves("+startStaff+"-"+endStaff+") Ticks("+cursor.tick+"-"+endTick+")");
            }      

            // initialize data structure

            var changed = [];
            var curNote = [];
            var prevNote = [];
            var curRest = [];
            var prevRest = [];
            var curTick = [];
            var prevTick = [];

            var foundParallels = 0;

            var track;

            var startTrack = startStaff * 4;
            var endTrack = endStaff * 4;

            for (track = startTrack; track < endTrack; track++) {
                  curRest[track] = true;
                  prevRest[track] = true;
                  changed[track] = false;
                  curNote[track] = 0;
                  prevNote[track] = 0;
                  curTick[track] = 0;
                  prevTick[track] = 0;
            }

            // go through all staves/voices simultaneously

            if(processAll) {
                  cursor.track = 0;
                  cursor.rewind(0);
            } else {
                  cursor.rewind(1);
            }

            var segment = cursor.segment;

            while (segment && (processAll || segment.tick < endTick)) {
                  // Pass 1: read notes
                  for (track = startTrack; track < endTrack; track++) {
                        if (segment.elementAt(track)) {
                              if (segment.elementAt(track).type == Element.CHORD) {
                                    // we ignore grace notes for now
                                    var notes = segment.elementAt(track).notes;

                                    if (notes.length > 1) {
                                          console.log("found chord with more than one note!");
                                          errorChords = true;
                                    }

                                    var note = notes[notes.length-1];

                                    // check for some voice rules
                                    // if we have a new pitch
                                    if ((! curRest[track]) 
                                         && curNote[track].pitch != note.pitch) {
                                          // previous note present
                                          // check for augmented interval
                                          if (isAugmentedInt(note, curNote[track])) {
                                                markText(curNote[track],note,
                                                "augmented interval",colorError,
                                                track,curTick[track]);
                                          }
                                          // check for diminished 4th and 7th
                                          checkDim47(curNote[track], note,
                                                track,curTick[track]);
                                          check7AndLarger(curNote[track],note,
                                                track,curTick[track],false);

                                          // have three notes?
                                          if (! prevRest[track]) {
                                                // check for diminished 5th
                                                checkDim5(prevNote[track],curNote[track],
                                                  note, track, prevTick[track]);
                                                // check for 6th
                                                check6NextNote(prevNote[track],curNote[track],
                                                  note, track, prevTick[track]);
                                                if(!isOctave(prevNote[track],curNote[track]) &&
                                                   !isOctave(curNote[track],note))
                                                      check7AndLarger(prevNote[track],note,
                                                        track,prevTick[track],true);
                                                check8(prevNote[track],curNote[track],note,
                                                      track, prevTick[track]);
                                          }
                                    }

                                    // remember note

                                    if (curNote[track].pitch != note.pitch) {
                                          prevTick[track]=curTick[track];
                                          prevRest[track]=curRest[track];
                                          prevNote[track]=curNote[track];
                                          changed[track]=true;
                                    } else {
                                          changed[track]=false;
                                    }
                                    curRest[track]=false;
                                    curNote[track]=note;
                                    curTick[track]=segment.tick;
                              } else if (segment.elementAt(track).type == Element.REST) {
                                    if (!curRest[track]) {
                                          // was note
                                          prevRest[track]=curRest[track];
                                          prevNote[track]=curNote[track];
                                          curRest[track]=true;
                                          changed[track]=false; // no need to check against a rest
                                    }
                              } else {
                                    changed[track] = false;
                              }
                        } else {
                              changed[track] = false;
                        }
                  }
                  // Pass 2: find paralleles
                  for (track=startTrack; track < endTrack; track++) {
                        var i;
                        // compare to other tracks
                        if (changed[track] && (!prevRest[track])) {
                              var dir1 = sgn(curNote[track].pitch - prevNote[track].pitch);
                              if (dir1 == 0) continue; // voice didn't move
                              for (i=track+1; i < endTrack; i++) {
                                    if (changed[i] && (!prevRest[i])) {
                                          var dir2 = sgn(curNote[i].pitch-prevNote[i].pitch);
                                          if (dir1 == dir2) { // both voices moving in the same direction
                                                var cint = curNote[track].pitch - curNote[i].pitch;
                                                var pint = prevNote[track].pitch-prevNote[i].pitch;
                                                // test for 5th
                                                if (Math.abs(cint%12) == 7) {
                                                      // test for open parallel
                                                      if (cint == pint) {
                                                            foundParallels++;
                                                            console.log ("P5:"+cint+", "+pint);
                                                            markText(prevNote[track],prevNote[i],"parallel 5th",
                                                                  colorFifth,track,prevTick[track]);
                                                            markColor(curNote[track],curNote[i],colorFifth);
                                                      } else if (dir1 == 1 && Math.abs(pint) < Math.abs(cint)) {
                                                            // hidden parallel (only when moving up)
                                                            foundParallels++;
                                                            console.log ("H5:"+cint+", "+pint);
                                                            markText(prevNote[track],prevNote[i],"hidden 5th",
                                                                  colorFifth,track,prevTick[track]);
                                                            markColor(curNote[track],curNote[i],colorFifth);
                                                      }                                                
                                                }
                                                // test for 8th
                                                if (Math.abs(cint%12) == 0) {
                                                      // test for open parallel
                                                      if (cint == pint) {
                                                            foundParallels++;
                                                            console.log ("P8:"+cint+", "+pint+"Tracks "+track+","+i+" Tick="+segment.tick);
                                                            markText(prevNote[track],prevNote[i],"parallel 8th",
                                                                  colorOctave,track,prevTick[track]);
                                                            markColor(curNote[track],curNote[i],colorOctave);
                                                      } else if (dir1 == 1 && Math.abs(pint) < Math.abs(cint)) {
                                                            // hidden parallel (only when moving up)
                                                            foundParallels++;
                                                            console.log ("H8:"+cint+", "+pint);
                                                            markText(prevNote[track],prevNote[i],"hidden 8th",
                                                                  colorOctave,track,prevTick[track]);
                                                            markColor(curNote[track],curNote[i],colorOctave);
                                                      }                                                
                                                }
                                          }
                                    }
                              }
                        }
                  }
                  segment = segment.next;
            }

            // set result dialog

            if (errorChords) {
                  console.log("finished with error");
                  msgMoreNotes.visible = true;
            } else {
                  console.log("finished");
                  Qt.quit();
            }
      }
}
