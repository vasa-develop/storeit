package com.storeit.storeit.fragments;

import android.accessibilityservice.GestureDescription;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.support.design.widget.CoordinatorLayout;
import android.support.design.widget.Snackbar;
import android.support.v4.app.Fragment;
import android.support.v7.app.AlertDialog;
import android.support.v7.widget.DefaultItemAnimator;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.util.Log;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.Toast;
import com.storeit.storeit.R;
import com.storeit.storeit.activities.MainActivity;
import com.storeit.storeit.adapters.ExplorerAdapter;
import com.storeit.storeit.protocol.StoreitFile;
import com.storeit.storeit.services.SocketService;
import com.storeit.storeit.utils.FilesManager;

import java.io.File;

public class FileViewerFragment extends Fragment {

    private ExplorerAdapter adapter;
    private OnFragmentInteractionListener mListener;
    private RecyclerView explorersRecyclerView;

    private boolean mMoving = false; // We are moving a file

    public ExplorerAdapter getAdapter() {
        return adapter;
    }

    public FileViewerFragment() {

    }

    public static FileViewerFragment newInstance(String param1, String param2) {
        return new FileViewerFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    CoordinatorLayout coordinatorLayout;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View rootView = inflater.inflate(R.layout.fragment_file_viewer, container, false);

        explorersRecyclerView = (RecyclerView) rootView.findViewById(R.id.explorer_recycler_view);
        explorersRecyclerView.setLayoutManager(new LinearLayoutManager(getActivity()));

        FilesManager manager = ((MainActivity) getActivity()).getFilesManager();

        coordinatorLayout = (CoordinatorLayout)rootView.findViewById(R.id.coordinatorLayout);

        adapter = new ExplorerAdapter(manager, getActivity());
        explorersRecyclerView.setAdapter(adapter);
        explorersRecyclerView.setItemAnimator(new DefaultItemAnimator());

        final GestureDetector mGestureDetector = new GestureDetector(rootView.getContext(), new GestureDetector.SimpleOnGestureListener() {
            @Override
            public boolean onSingleTapUp(MotionEvent e) {
                return true;
            }
        });

        explorersRecyclerView.addOnItemTouchListener(new RecyclerView.OnItemTouchListener() {
            @Override
            public boolean onInterceptTouchEvent(RecyclerView rv, MotionEvent e) {

                View child = explorersRecyclerView.findChildViewUnder(e.getX(), e.getY());
                if (child != null && mGestureDetector.onTouchEvent(e)) {
                    Log.v("FILE_FRAGMENT", "file fragment clicked : " + explorersRecyclerView.getChildLayoutPosition(child));
                    adapter.fileClicked(explorersRecyclerView.getChildLayoutPosition(child));
                    return true;
                }
                return false;
            }

            @Override
            public void onTouchEvent(RecyclerView rv, MotionEvent e) {
            }

            @Override
            public void onRequestDisallowInterceptTouchEvent(boolean disallowIntercept) {

            }
        });

        registerForContextMenu(explorersRecyclerView);

        return rootView;
    }

    public void backPressed() {
        adapter.backPressed();
    }

    public void onButtonPressed(Uri uri) {
        if (mListener != null) {
            mListener.onFragmentInteraction(uri);
        }
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    @Override
    public boolean onContextItemSelected(MenuItem item) {
        if (mMoving)
            return super.onContextItemSelected(item);

        int position = adapter.getPosition();

        MainActivity activity = (MainActivity) getActivity();
        final FilesManager manager = activity.getFilesManager();
        final StoreitFile file = adapter.getFileAt(position);
        final SocketService service = activity.getSocketService();

        switch (item.getItemId()) {
            case R.id.action_delete_file:
                Log.v("FileViewerFragment", "Delete");
                manager.removeFile(file.getPath());
                adapter.removeFile(position);
                service.sendFDEL(file);
                break;
            case R.id.action_delete_file_disk:
                if (!file.isDirectory()) {
                    File localFile = new File(manager.getFolderPath() + File.separator + file.getIPFSHash());
                    if (!localFile.delete()) {
                        Toast.makeText(getContext(), "Error while deleting file", Toast.LENGTH_SHORT).show();
                    }
                }
                break;
            case R.id.action_rename_file:
                renameFile(manager, file);
                break;
            case R.id.action_move_file:
                View focus = getActivity().getCurrentFocus();
                if (focus == null)
                    break;

                mMoving = true;
                ((MainActivity)getActivity()).getFloatingButton().setVisibility(View.GONE); // floating button

                Snackbar snackbar = Snackbar.make(focus, "Move file", Snackbar.LENGTH_INDEFINITE)
                        .setAction("MOVE", new View.OnClickListener() {
                            @Override
                            public void onClick(View view) {
                                ((MainActivity)getActivity()).getFloatingButton().setVisibility(View.VISIBLE);
                                mMoving = false;

                                String oldPath = file.getPath();
                                String movedPath = getCurrentFile().getPath() +File.separator + file.getFileName();
                                movedPath = movedPath.replace("//", "/");

                                manager.removeFile(file.getPath());

                                file.setPath(movedPath);

                                manager.addFile(file, getCurrentFile());
                                adapter.reloadFiles();
                                service.sendFMOV(oldPath, movedPath);
                            }
                        });
                snackbar.setCallback(new Snackbar.Callback() {
                    @Override
                    public void onDismissed(Snackbar snackbar, int event) {
                        super.onDismissed(snackbar, event);
                        ((MainActivity)getActivity()).getFloatingButton().setVisibility(View.VISIBLE);
                        mMoving = false;
                    }
                });

                snackbar.setActionTextColor(Color.RED);
                snackbar.show();
                break;

        }

        return super.onContextItemSelected(item);
    }

    private void renameFile(final FilesManager manager, final StoreitFile file) {
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        LayoutInflater inflater = getActivity().getLayoutInflater();

        builder.setTitle("Save picture");
        View dialogView = inflater.inflate(R.layout.dialog_name_file, null);
        builder.setView(dialogView);

        final EditText input = (EditText) dialogView.findViewById(R.id.dialog_file_name_input);

        builder.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {

                String fileName = input.getText().toString();
                File f = new File(file.getPath()); // Get parent path

                String finalName = f.getParent() + File.separator + fileName;
                finalName = finalName.replace("//", "/");
                ((MainActivity) getActivity()).getSocketService().sendFMOV(file.getPath(), finalName);
                manager.moveFile(file.getPath(), finalName);
                adapter.reloadFiles();

            }
        }).setNegativeButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                dialogInterface.cancel();
            }
        }).show();
    }

    public interface OnFragmentInteractionListener {
        void onFragmentInteraction(Uri uri);
    }

    public StoreitFile getCurrentFile() {
        return adapter.getCurrentFile();
    }
}
